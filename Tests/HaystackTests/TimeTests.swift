import XCTest
@testable import Haystack

final class TimeTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Time(hour: 7, minute: 7, second: 7, millisecond: 7)
        let jsonString = #"{"_kind":"time","val":"07:07:07.007"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: decodedData),
            value
        )
    }
    
    func testJsonCoding_zeroMillis() throws {
        let value = Time(hour: 7, minute: 7, second: 7, millisecond: 0)
        let jsonString = #"{"_kind":"time","val":"07:07:07"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: decodedData),
            value
        )
    }
}
