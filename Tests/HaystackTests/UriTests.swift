import Haystack
import XCTest

final class UriTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Uri("http://en.wikipedia.org/")
        let jsonString = #"{"_kind":"uri","val":"http:\/\/en.wikipedia.org\/"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Uri.self, from: encodedData),
            value
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
