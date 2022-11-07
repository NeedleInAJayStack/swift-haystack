import XCTest
import Haystack

final class DateTimeTests: XCTestCase {
    func testJsonCoding() throws {
        let value = DateTime(
            date: Date(timeIntervalSince1970: 0.458),
            timezone: DateTime.gmtName
        )
        let jsonString = #"{"_kind":"dateTime","val":"1970-01-01T00:00:00.458Z"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: decodedData),
            value
        )
    }
    
    func testJsonCoding_noMilliseconds() throws {
        let value = DateTime(
            date: Date(timeIntervalSince1970: 0),
            timezone: "New_York"
        )
        let jsonString = #"{"_kind":"dateTime","val":"1970-01-01T00:00:00Z","tz":"New_York"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(DateTime.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            DateTime(
                date: Date(timeIntervalSince1970: 0),
                timezone: DateTime.gmtName
            ).toZinc(),
            "1970-01-01T00:00:00Z"
        )
        
        // TODO: Fix to 1970-01-01T00:00:00-05:00 New_York
        XCTAssertEqual(
            DateTime(
                date: Date(timeIntervalSince1970: 0),
                timezone: "New_York"
            ).toZinc(),
            "1970-01-01T00:00:00Z New_York"
        )
    }
}
