@testable import Haystack
import Testing

struct ZincTokenizerTests {
    @Test func empty() throws {
        try expectEqualTokensAndVals(zinc: "", expected: [])
    }

    @Test func id() throws {
        try expectEqualTokensAndVals(zinc: "x", expected: [(.id, "x")])
        try expectEqualTokensAndVals(zinc: "fooBar", expected: [(.id, "fooBar")])
        try expectEqualTokensAndVals(zinc: "fooBar1999x", expected: [(.id, "fooBar1999x")])
        try expectEqualTokensAndVals(zinc: "foo_23", expected: [(.id, "foo_23")])
        try expectEqualTokensAndVals(zinc: "Foo", expected: [(.id, "Foo")])
    }

    @Test func num() throws {
        try expectEqualTokensAndVals(zinc: "5", expected: [(.num, Number(5))])
        try expectEqualTokensAndVals(zinc: "0x1234_abcd", expected: [(.num, Number(0x1234_ABCD))])
    }

    @Test func floats() throws {
        try expectEqualTokensAndVals(zinc: "5.0", expected: [(.num, Number(5))])
        try expectEqualTokensAndVals(zinc: "5.42", expected: [(.num, Number(5.42))])
        try expectEqualTokensAndVals(zinc: "123.2e32", expected: [(.num, Number(123.2e32))])
        try expectEqualTokensAndVals(zinc: "123.2e+32", expected: [(.num, Number(123.2e+32))])
        try expectEqualTokensAndVals(zinc: "2_123.2e+32", expected: [(.num, Number(2123.2e+32))])
        try expectEqualTokensAndVals(zinc: "4.2e-7", expected: [(.num, Number(4.2e-7))])
    }

    @Test func numberWithUnits() throws {
        try expectEqualTokensAndVals(zinc: "-40ms", expected: [(.num, Number(-40, unit: "ms"))])
        try expectEqualTokensAndVals(zinc: "1sec", expected: [(.num, Number(1, unit: "sec"))])
        try expectEqualTokensAndVals(zinc: "5hr", expected: [(.num, Number(5, unit: "hr"))])
        try expectEqualTokensAndVals(zinc: "2.5day", expected: [(.num, Number(2.5, unit: "day"))])
        try expectEqualTokensAndVals(zinc: "12%", expected: [(.num, Number(12, unit: "%"))])
        try expectEqualTokensAndVals(zinc: "987_foo", expected: [(.num, Number(987, unit: "_foo"))])
        try expectEqualTokensAndVals(zinc: "-1.2m/s", expected: [(.num, Number(-1.2, unit: "m/s"))])
        try expectEqualTokensAndVals(zinc: #"12kWh/ft\u00B2"#, expected: [(.num, Number(12, unit: "kWh/ft\u{00B2}"))])
        try expectEqualTokensAndVals(zinc: "3_000.5J/kg_dry", expected: [(.num, Number(3000.5, unit: "J/kg_dry"))])
    }

    @Test func strings() throws {
        try expectEqualTokensAndVals(zinc: #""""#, expected: [(.str, "")])
        try expectEqualTokensAndVals(zinc: #""x y""#, expected: [(.str, "x y")])
        try expectEqualTokensAndVals(zinc: #""x\"y""#, expected: [(.str, #"x"y"#)])
        try expectEqualTokensAndVals(zinc: #""_\u012f \n \t \\_""#, expected: [(.str, "_\u{012f} \n \t \\_")])
    }

    @Test func date() throws {
        try expectEqualTokensAndVals(zinc: "2016-06-06", expected: [(.date, Date(year: 2016, month: 06, day: 06))])
    }

    @Test func time() throws {
        try expectEqualTokensAndVals(zinc: "8:30", expected: [(.time, Time(hour: 8, minute: 30, second: 0))])
        try expectEqualTokensAndVals(zinc: "20:15", expected: [(.time, Time(hour: 20, minute: 15, second: 0))])
        try expectEqualTokensAndVals(zinc: "00:00", expected: [(.time, Time(hour: 0, minute: 0, second: 0))])
        try expectEqualTokensAndVals(zinc: "00:00:00", expected: [(.time, Time(hour: 0, minute: 0, second: 0))])
        try expectEqualTokensAndVals(zinc: "01:02:03", expected: [(.time, Time(hour: 1, minute: 2, second: 3))])
        try expectEqualTokensAndVals(zinc: "23:59:59", expected: [(.time, Time(hour: 23, minute: 59, second: 59))])
        try expectEqualTokensAndVals(zinc: "12:00:12.9", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 900))])
        try expectEqualTokensAndVals(zinc: "12:00:12.99", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 990))])
        try expectEqualTokensAndVals(zinc: "12:00:12.999", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 999))])
        try expectEqualTokensAndVals(zinc: "12:00:12.000", expected: [(.time, Time(hour: 12, minute: 0, second: 12))])
        try expectEqualTokensAndVals(zinc: "12:00:12.001", expected: [(.time, Time(hour: 12, minute: 0, second: 12, millisecond: 1))])
    }

    @Test func dateTime() throws {
        try expectEqualTokensAndVals(
            zinc: "2016-01-13T09:51:33-05:00 New_York",
            expected: [(.datetime, DateTime(year: 2016, month: 1, day: 13, hour: 9, minute: 51, second: 33, gmtOffset: -5 * 60 * 60, timezone: "New_York"))]
        )
        try expectEqualTokensAndVals(
            zinc: "2016-01-13T09:51:33.352-05:00 New_York",
            expected: [(.datetime, DateTime(year: 2016, month: 1, day: 13, hour: 9, minute: 51, second: 33, millisecond: 352, gmtOffset: -5 * 60 * 60, timezone: "New_York"))]
        )
        try expectEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z",
            expected: [(.datetime, DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: DateTime.utcName))]
        )
        try expectEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z UTC",
            expected: [(.datetime, DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: DateTime.utcName))]
        )
        try expectEqualTokensAndVals(
            zinc: "2010-12-18T14:11:30.924Z London",
            expected: [(.datetime, DateTime(year: 2010, month: 12, day: 18, hour: 14, minute: 11, second: 30, millisecond: 924, timezone: "London"))]
        )
        try expectEqualTokensAndVals(
            zinc: "2010-03-01T23:55:00.013-05:00 GMT+5",
            expected: [(.datetime, DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: -5 * 60 * 60, timezone: "GMT+5"))]
        )
        try expectEqualTokensAndVals(
            zinc: "2010-03-01T23:55:00.013+10:00 GMT-10",
            expected: [(.datetime, DateTime(year: 2010, month: 3, day: 1, hour: 23, minute: 55, second: 0, millisecond: 13, gmtOffset: 10 * 60 * 60, timezone: "GMT-10"))]
        )
    }

    @Test func ref() throws {
        try expectEqualTokensAndVals(zinc: "@125b780e-0684e169", expected: [(.ref, Ref("125b780e-0684e169"))])
        try expectEqualTokensAndVals(zinc: "@demo:_:-.~", expected: [(.ref, Ref("demo:_:-.~"))])
    }

    @Test func uri() throws {
        try expectEqualTokensAndVals(zinc: "`http://foo/`", expected: [(.uri, Uri("http://foo/"))])
        try expectEqualTokensAndVals(zinc: "`_ \\n \\\\ \\`_`", expected: [(.uri, Uri("_ \n \\\\ `_"))])
    }

    @Test func whitespace() throws {
        try expectEqualTokensAndVals(
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

    private func expectEqualTokensAndVals(
        zinc: String,
        expected: [(ZincToken, (any Val)?)],
        file _: StaticString = #filePath,
        line _: UInt = #line
    ) throws {
        var actual = [(ZincToken, (any Val)?)]()
        let tokenizer = try ZincTokenizer(zinc)
        while true {
            let token = try tokenizer.next()
            #expect(token == tokenizer.token)
            if token == ZincToken.eof {
                break
            }
            actual.append((token, tokenizer.val))
        }

        #expect(actual.count == expected.count, "\(actual) does not equal \(expected)")
        for (actualElement, expectedElement) in zip(actual, expected) {
            #expect(actualElement.0 == expectedElement.0)
            switch actualElement.1 {
            case .none:
                switch expectedElement.1 {
                case .none:
                    continue
                case let .some(expectedVal):
                    Issue.record("Val nil does not equal \(expectedVal)")
                }
            case let .some(actualVal):
                switch expectedElement.1 {
                case .none:
                    Issue.record("Val \(actualVal) does not equal nil")
                case let .some(expectedVal):
                    #expect(
                        actualVal.equals(expectedVal),
                        "Val \(actualVal) does not equal \(expectedVal)"
                    )
                }
            }
        }
    }
}
