import Haystack
import XCTest

final class RemoveTests: XCTestCase {
    func testJsonCoding() throws {
        let value = remove
        let jsonString = #"{"_kind":"remove"}"#

        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )

        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Remove.self, from: decodedData),
            value
        )
    }

    func testToZinc() throws {
        XCTAssertEqual(
            remove.toZinc(),
            "R"
        )
    }
}
