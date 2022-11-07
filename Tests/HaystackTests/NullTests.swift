import XCTest
import Haystack

final class NullTests: XCTestCase {
    func testJsonCoding() throws {
        let value = null
        let jsonString = #"null"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Null.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            null.toZinc(),
            "N"
        )
    }
}
