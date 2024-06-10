import XCTest
import Haystack

final class DateTimeTests: XCTestCase {
    func testJsonCoding() throws {
        let value = try DateTime(
            year: 1988,
            month: 4,
            day: 1,
            hour: 10,
            minute: 5,
            second: 43,
            millisecond: 458,
            gmtOffset: -5*60*60,
            timezone: "New_York"
        )
        let jsonString = #"{"_kind":"dateTime","val":"1988-04-01T10:05:43.458-05:00","tz":"New_York"}"#
        
        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: encodedData),
            value
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: decodedData),
            value
        )
    }
    
    func testJsonCoding_noMilliseconds() throws {
        let value = try DateTime(
            year: 1988,
            month: 4,
            day: 1,
            hour: 10,
            minute: 5,
            second: 43,
            gmtOffset: -5*60*60,
            timezone: "New_York"
        )
        let jsonString = #"{"_kind":"dateTime","val":"1988-04-01T10:05:43-05:00","tz":"New_York"}"#
        
        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: encodedData),
            value
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            try DateTime(
                year: 1988,
                month: 4,
                day: 1,
                hour: 10,
                minute: 5,
                second: 43,
                gmtOffset: 0,
                timezone: DateTime.utcName
            ).toZinc(),
            "1988-04-01T10:05:43Z"
        )
        
        XCTAssertEqual(
            try DateTime(
                year: 1988,
                month: 4,
                day: 1,
                hour: 10,
                minute: 5,
                second: 43,
                gmtOffset: -5*60*60,
                timezone: "New_York"
            ).toZinc(),
            "1988-04-01T10:05:43-05:00 New_York"
        )
    }
}
