import XCTest
@testable import Haystack

final class NATests: XCTestCase {
    func testJsonCoding() throws {
        let value = na
        let jsonString = #"{"_kind":"na"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(NA.self, from: decodedData),
            value
        )
    }
}
