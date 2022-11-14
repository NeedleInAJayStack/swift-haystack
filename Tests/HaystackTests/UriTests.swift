import XCTest
import Haystack

final class UriTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Uri("http://en.wikipedia.org/")
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
    
    func testToZinc() throws {
        XCTAssertEqual(
            Uri("http://en.wikipedia.org/").toZinc(),
            "`http://en.wikipedia.org/`"
        )
    }
}
