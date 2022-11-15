import XCTest
import Haystack

final class SymbolTests: XCTestCase {
    func testInit() throws {
        try XCTAssertThrowsError(Symbol("tag name"))
        try XCTAssertThrowsError(Symbol("tag name"))
        try XCTAssertThrowsError(Symbol("tag name"))
    }
    
    func testJsonCoding() throws {
        let value = try Symbol("tagName")
        let jsonString = #"{"_kind":"symbol","val":"tagName"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Symbol.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            try Symbol("tagName").toZinc(),
            "^tagName"
        )
    }
}
