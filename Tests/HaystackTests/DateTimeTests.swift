import Foundation
import Haystack
import Testing

struct DateTimeTests {
    @Test func jsonCoding() throws {
        let value = try DateTime(
            year: 1988,
            month: 4,
            day: 1,
            hour: 10,
            minute: 5,
            second: 43,
            millisecond: 458,
            gmtOffset: -5 * 60 * 60,
            timezone: "New_York"
        )
        let jsonString = #"{"_kind":"dateTime","val":"1988-04-01T10:05:43.458-05:00","tz":"New_York"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(DateTime.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(DateTime.self, from: decodedData) == value)
    }

    @Test func jsonCoding_noMilliseconds() throws {
        let value = try DateTime(
            year: 1988,
            month: 4,
            day: 1,
            hour: 10,
            minute: 5,
            second: 43,
            gmtOffset: -5 * 60 * 60,
            timezone: "New_York"
        )
        let jsonString = #"{"_kind":"dateTime","val":"1988-04-01T10:05:43-05:00","tz":"New_York"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(DateTime.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(DateTime.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(
            try DateTime(
                year: 1988,
                month: 4,
                day: 1,
                hour: 10,
                minute: 5,
                second: 43,
                gmtOffset: 0,
                timezone: DateTime.utcName
            ).toZinc() == "1988-04-01T10:05:43Z"
        )

        #expect(
            try DateTime(
                year: 1988,
                month: 4,
                day: 1,
                hour: 10,
                minute: 5,
                second: 43,
                gmtOffset: -5 * 60 * 60,
                timezone: "New_York"
            ).toZinc() == "1988-04-01T10:05:43-05:00 New_York"
        )
    }
}
