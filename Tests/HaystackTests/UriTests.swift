import XCTest
@testable import Haystack

final class UriTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Uri(val: "http://en.wikipedia.org/")
        let jsonString = #"{"_kind":"uri","val":"http:\/\/en.wikipedia.org\/"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Uri.self, from: decodedData),
            value
        )
    }
}
