import XCTest
import Haystack

final class ZincReaderTests: XCTestCase {
    func testNullGridMetaAndColMeta() throws {
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0" tag:N
                a nullmetatag:N, b markermetatag
                
                """,
            meta: ["tag": null],
            cols: [("a", ["nullmetatag": null]), ("b", ["markermetatag": marker])],
            rows: []
        )
    }
    
    func testGridWithSymbols() throws {
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a,b
                ^foo,^a-b
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil)],
            rows: [
                [Symbol(val: "foo"), Symbol(val: "a-b")]
            ]
        )
    }
    
    func test() throws {
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                fooBar33
                
                """,
            meta: [:],
            cols: [("fooBar33", nil)],
            rows: []
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0" tag foo:"bar"
                xyz
                "val"
                """,
            meta: ["tag": marker, "foo": "bar"],
            cols: [("xyz", nil)],
            rows: [
                ["val"]
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                val
                N
                """,
            meta: [:],
            cols: [
                ("val", nil),
            ],
            rows: [
                [null]
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a,b
                1,2
                3,4
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil)],
            rows: [
                [Number(val: 1), Number(val: 2)],
                [Number(val: 3), Number(val: 4)],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a,    b,      c,      d
                T,    F,      N,   -99
                2.3,  -5e-10, 2.4e20, 123e-10
                "",   "a",   "\\" \\\\ \t \n \r", "\\uabcd"
                `path`, @12cbb082-0c02ae73, 4s, -2.5min
                M,R,N,N
                2009-12-31, 23:59:01, 01:02:03.123, 2009-02-03T04:05:06Z
                INF, -INF, \"\", NaN
                C(12,-34),C(0.123,-0.789),C(84.5,-77.45),C(-90,180)
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil), ("c", nil), ("d", nil)],
            rows: [
                [true, false, null, Number(val: -99)],
                [Number(val: 2.3), Number(val: -5e-10), Number(val: 2.4e20), Number(val: 123e-10)],
                ["", "a", "\" \\ \t \n \r", "\u{abcd}"],
                [Uri(val: "path"), Ref(val: "12cbb082-0c02ae73"), Number(val: 4, unit: "s"), Number(val: -2.5, unit: "min")],
                [marker, remove, null, null], // Bin not supported.
                [Date(year: 2009, month: 12, day: 31), Time(hour: 23, minute: 59, second: 1), Time(hour: 1, minute: 2, second: 3, millisecond: 123), DateTime(year: 2009, month: 2, day: 3, hour: 4, minute: 5, second: 6)],
                [Number(val: .infinity), Number(val: -1 * .infinity), "", Number(val: .nan)],
                [Coord(lat: 12, lng: -34), Coord(lat: 0.123, lng: -0.789), Coord(lat: 84.5, lng: -77.45), Coord(lat: -90, lng: 180)],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                foo
                `foo$20bar`
                `foo\\`bar`
                `file \\#2`
                "$15"
                """,
            meta: [:],
            cols: [("foo", nil)],
            rows: [
                [Uri(val: "foo$20bar")],
                [Uri(val: "foo`bar")],
                [Uri(val: "file \\#2")],
                ["$15"],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a,b
                -3.1kg,4kg
                5%,3.2%
                5kWh/ft\\u00b2,-15kWh/m\\u00b2
                123e+12kJ/kg_dry,74\\u0394\\u0b0F
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil)],
            rows: [
                [Number(val: -3.1, unit: "kg"), Number(val: 4, unit: "kg")],
                [Number(val: 5, unit: "%"), Number(val: 3.2, unit: "%")],
                [Number(val: 5, unit: "kWh/ft\u{00b2}"), Number(val: -15, unit: "kWh/m\u{00b2}")],
                [Number(val: 123e+12, unit: "kJ/kg_dry"), Number(val: 74, unit: "\u{0394}\u{0b0F}")],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a, b, c
                , 1, 2
                3, , 5
                6, 7_000,
                ,,10
                ,,
                14,,
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil), ("c", nil)],
            rows: [
                [null, Number(val: 1), Number(val: 2)],
                [Number(val: 3), null, Number(val: 5)],
                [Number(val: 6), Number(val: 7000), null],
                [null, null, Number(val: 10)],
                [null, null, null],
                [Number(val: 14), null, null],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0"
                a,b
                2010-03-01T23:55:00.013-05:00 GMT+5,2010-03-01T23:55:00.013+10:00 GMT-10
                """,
            meta: [:],
            cols: [("a", nil), ("b", nil)],
            rows: [
                [
                    DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: -5*60*60, timezone: "GMT+5"),
                    DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: 10*60*60, timezone: "GMT-10"),
                ],
            ]
        )
        
        try XCTAssertEqualZincGrid(
            zinc: """
                ver:"3.0" a: 2009-02-03T04:05:06Z foo b: 2010-02-03T04:05:06Z UTC bar c: 2009-12-03T04:05:06Z London baz
                a
                3.814697265625E-6
                2010-12-18T14:11:30.924Z
                2010-12-18T14:11:30.925Z UTC
                2010-12-18T14:11:30.925Z London
                45$
                33\\u00a3
                @12cbb08e-0c02ae73
                7.15625E-4kWh/ft\\u00b2
                R
                NA
                """,
            meta: [
                "a": DateTime(year: 2009, month: 2, day: 3, hour: 4, minute: 5, second: 6),
                "foo": marker,
                "b": DateTime(year: 2010, month: 2, day: 3, hour: 4, minute: 5, second: 6),
                "bar": marker,
                "c": DateTime(year: 2009, month: 12, day: 3, hour: 4, minute: 5, second: 6, timezone: "London"),
                "baz": marker,
            ],
            cols: [("a", nil)],
            rows: [
                [Number(val: 3.814697265625E-6)],
                [DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924)],
                [DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 925)],
                [DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 925, timezone: "London")],
                [Number(val: 45, unit: "$")],
                [Number(val: 33, unit: "\u{00a3}")],
                [Ref(val: "12cbb08e-0c02ae73")],
                [Number(val: 7.15625E-4, unit: "kWh/ft\u{00b2}")],
                [remove],
                [na],
            ]
        )
    }
    
    private func XCTAssertEqualZincGrid(
        zinc: String,
        meta: [String: any Val],
        cols: [(String, [String: any Val]?)],
        rows: [[any Val]],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let actual = try ZincReader(zinc).readGrid()
        
        let builder = GridBuilder()
        builder.setMeta(meta)
        for (colName, colMeta) in cols {
            try builder.addCol(name: colName, meta: colMeta)
        }
        for row in rows {
            try builder.addRow(row)
        }
        let expected = builder.toGrid()
        
        XCTAssertEqual(
            actual,
            expected,
            """
            \(actual.toZinc())
            is not equal to
            \(expected.toZinc())
            """
        )
    }
}
