import XCTest
@testable import Haystack

final class SymbolTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Symbol(val: "tagName")
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
}
