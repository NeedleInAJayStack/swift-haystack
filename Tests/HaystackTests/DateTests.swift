import XCTest
@testable import Haystack

final class DateTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Date(date: .init(timeIntervalSince1970: 0))
        let jsonString = #"{"_kind":"date","val":"1970-01-01"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Date.self, from: decodedData),
            value
        )
    }
}
