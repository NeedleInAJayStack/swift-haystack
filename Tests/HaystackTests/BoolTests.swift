import XCTest
import Haystack

final class BoolTests: XCTestCase {
    func testJsonCoding() throws {
        let value = true
        let jsonString = #"true"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Bool.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(false.toZinc(), "F")
        XCTAssertEqual(true.toZinc(), "T")
    }
    
    func testComparable() throws {
        XCTAssertFalse(false < false)
        XCTAssertTrue(false < true)
        XCTAssertFalse(true < false)
        XCTAssertFalse(true < true)
    }
}
