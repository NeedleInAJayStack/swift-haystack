import XCTest
@testable import Haystack

final class ZincTokenizerTests: XCTestCase {
    func testEmpty() throws {
        try XCTAssertEqualTokensAndVals(zinc: "", expected: [])
    }
    
    func testId() throws {
        try XCTAssertEqualTokensAndVals(zinc: "x", expected: [(.id, "x")])
        try XCTAssertEqualTokensAndVals(zinc: "fooBar", expected: [(.id, "fooBar")])
        try XCTAssertEqualTokensAndVals(zinc: "fooBar1999x", expected: [(.id, "fooBar1999x")])
        try XCTAssertEqualTokensAndVals(zinc: "foo_23", expected: [(.id, "foo_23")])
        try XCTAssertEqualTokensAndVals(zinc: "Foo", expected: [(.id, "Foo")])
    }
    
    func testNum() throws {
        try XCTAssertEqualTokensAndVals(zinc: "5", expected: [(.num, Number(val: 5))])
        try XCTAssertEqualTokensAndVals(zinc: "0x1234_abcd", expected: [(.num, Number(val: 0x1234abcd))])
    }
    
    func testFloats() throws {
        try XCTAssertEqualTokensAndVals(zinc: "5.0", expected: [(.num, Number(val: 5))])
        try XCTAssertEqualTokensAndVals(zinc: "5.42", expected: [(.num, Number(val: 5.42))])
        try XCTAssertEqualTokensAndVals(zinc: "123.2e32", expected: [(.num, Number(val: 123.2e32))])
        try XCTAssertEqualTokensAndVals(zinc: "123.2e+32", expected: [(.num, Number(val: 123.2e+32))])
        try XCTAssertEqualTokensAndVals(zinc: "2_123.2e+32", expected: [(.num, Number(val: 2_123.2e+32))])
        try XCTAssertEqualTokensAndVals(zinc: "4.2e-7", expected: [(.num, Number(val: 4.2e-7))])
    }
    
    func testNumberWithUnits() throws {
        try XCTAssertEqualTokensAndVals(zinc: "-40ms", expected: [(.num, Number(val: -40, unit: "ms"))])
        try XCTAssertEqualTokensAndVals(zinc: "1sec", expected: [(.num, Number(val: 1, unit: "sec"))])
        try XCTAssertEqualTokensAndVals(zinc: "5hr", expected: [(.num, Number(val: 5, unit: "hr"))])
        try XCTAssertEqualTokensAndVals(zinc: "2.5day", expected: [(.num, Number(val: 2.5, unit: "day"))])
        try XCTAssertEqualTokensAndVals(zinc: "12%", expected: [(.num, Number(val: 12, unit: "%"))])
        try XCTAssertEqualTokensAndVals(zinc: "987_foo", expected: [(.num, Number(val: 987, unit: "_foo"))])
        try XCTAssertEqualTokensAndVals(zinc: "-1.2m/s", expected: [(.num, Number(val: -1.2, unit: "m/s"))])
        try XCTAssertEqualTokensAndVals(zinc: #"12kWh/ft\u00B2"#, expected: [(.num, Number(val: 12, unit: "kWh/ft\u{00B2}"))])
        try XCTAssertEqualTokensAndVals(zinc: "3_000.5J/kg_dry", expected: [(.num, Number(val: 3000.5, unit: "J/kg_dry"))])
    }
    
    func testStrings() throws {
        try XCTAssertEqualTokensAndVals(zinc: #""""#, expected: [(.str, "")])
        try XCTAssertEqualTokensAndVals(zinc: #""x y""#, expected: [(.str, "x y")])
        try XCTAssertEqualTokensAndVals(zinc: #""x\"y""#, expected: [(.str, #"x"y"#)])
        try XCTAssertEqualTokensAndVals(zinc: #""_\u012f \n \t \\_""#, expected: [(.str, "_\u{012f} \n \t \\_")])
    }
    
    func testDate() throws {
        try XCTAssertEqualTokensAndVals(zinc: "2016-06-06", expected: [(.date, Date(year: 2016, month: 06, day: 06))])
    }
    
    func testTime() throws {
        try XCTAssertEqualTokensAndVals(zinc: "8:30", expected: [(.time, Time(hour: 8, minute: 30, second: 0))])
        try XCTAssertEqualTokensAndVals(zinc: "20:15", expected: [(.time, Time(hour: 20, minute: 15, second: 0))])
        try XCTAssertEqualTokensAndVals(zinc: "00:00", expected: [(.time, Time(hour: 0, minute: 0, second: 0))])
        try XCTAssertEqualTokensAndVals(zinc: "00:00:00", expected: [(.time, Time(hour: 0, minute: 0, second: 0))])
        try XCTAssertEqualTokensAndVals(zinc: "01:02:03", expected: [(.time, Time(hour: 1, minute: 2, second: 3))])
        try XCTAssertEqualTokensAndVals(zinc: "23:59:59", expected: [(.time, Time(hour: 23, minute: 59, second: 59))])
        try XCTAssertEqualTokensAndVals(zinc: "12:00:12.9", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 900))])
        try XCTAssertEqualTokensAndVals(zinc: "12:00:12.99", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 990))])
        try XCTAssertEqualTokensAndVals(zinc: "12:00:12.999", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 999))])
        try XCTAssertEqualTokensAndVals(zinc: "12:00:12.000", expected: [(.time, Time(hour: 12, minute: 0, second: 12))])
        try XCTAssertEqualTokensAndVals(zinc: "12:00:12.001", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 1))])
    }
    
    // TODO: Fix these!
    func testDateTime() throws {
        try XCTAssertEqualTokensAndVals(
            zinc: "2016-01-13T09:51:33-05:00 New_York",
            expected: [(.datetime, try DateTime(year: 2016, month: 1, day: 13, hour: 9, minute: 51, second: 33, gmtOffset: -5*60*60, timezone: "New_York"))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2016-01-13T09:51:33.352-05:00 New_York",
            expected: [(.datetime, try DateTime(year: 2016, month: 1, day: 13, hour: 9, minute: 51, second: 33, millisecond: 352, gmtOffset: -5*60*60, timezone: "New_York"))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z",
            expected: [(.datetime, try DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: DateTime.utcName))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z UTC",
            expected: [(.datetime, try DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: DateTime.utcName))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z London",
            expected: [(.datetime, try DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: "London"))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2010-03-01T23:55:00.013-05:00 GMT+5",
            expected: [(.datetime, try DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: -5*60*60, timezone: "GMT+5"))]
        )
        try XCTAssertEqualTokensAndVals(
            zinc: "2010-03-01T23:55:00.013+10:00 GMT-10",
            expected: [(.datetime, try DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: 10*60*60, timezone: "GMT-10"))]
        )
    }
    
    func testRef() throws {
        try XCTAssertEqualTokensAndVals(zinc: "@125b780e-0684e169", expected: [(.ref, Ref(val: "125b780e-0684e169"))])
        try XCTAssertEqualTokensAndVals(zinc: "@demo:_:-.~", expected: [(.ref, Ref(val: "demo:_:-.~"))])
    }
    
    func testUri() throws {
        try XCTAssertEqualTokensAndVals(zinc: "`http://foo/`", expected: [(.uri, Uri(val: "http://foo/"))])
        try XCTAssertEqualTokensAndVals(zinc: "`_ \\n \\\\ \\`_`", expected: [(.uri, Uri(val: "_ \n \\\\ `_"))])
    }
    
    func testWhitespace() throws {
        try XCTAssertEqualTokensAndVals(
            zinc: "a\n  b   \rc \r\nd\n\ne",
            expected: [
                (.id, "a"),
                (.nl, null),
                (.id, "b"),
                (.nl, null),
                (.id, "c"),
                (.nl, null),
                (.id, "d"),
                (.nl, null),
                (.nl, null),
                (.id, "e"),
            ]
        )
    }
    
    private func XCTAssertEqualTokensAndVals(
        zinc: String,
        expected: [(ZincToken, (any Val)?)],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var actual = [(ZincToken, (any Val)?)]()
        let tokenizer = try ZincTokenizer(zinc)
        while true {
            let token = try tokenizer.next()
            XCTAssertEqual(token, tokenizer.token)
            if token == ZincToken.eof {
                break
            }
            actual.append((token, tokenizer.val))
        }
        
        XCTAssertEqual(actual.count, expected.count, "\(actual) does not equal \(expected)")
        for (actualElement, expectedElement) in zip(actual, expected) {
            XCTAssertEqual(actualElement.0, expectedElement.0)
            switch actualElement.1 {
            case .none:
                switch expectedElement.1 {
                case .none:
                    continue
                case let .some(expectedVal):
                    XCTFail("Val nil does not equal \(expectedVal)")
                }
            case let .some(actualVal):
                switch expectedElement.1 {
                case .none:
                    XCTFail("Val \(actualVal) does not equal nil")
                case let .some(expectedVal):
                    XCTAssertTrue(
                        actualVal.equals(expectedVal),
                        "Val \(actualVal) does not equal \(expectedVal)"
                    )
                }
            }
        }
    }
}
