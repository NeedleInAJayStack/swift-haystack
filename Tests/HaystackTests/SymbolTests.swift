import Foundation
import Haystack
import Testing

struct SymbolTests {
    @Test func testInit() throws {
        #expect(throws: SymbolError.self) { try Symbol("tag name") }
        #expect(throws: SymbolError.self) { try Symbol("tag name") }
        #expect(throws: SymbolError.self) { try Symbol("tag name") }
    }

    @Test func jsonCoding() throws {
        let value = try Symbol("tagName")
        let jsonString = #"{"_kind":"symbol","val":"tagName"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Symbol.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Symbol.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(try Symbol("tagName").toZinc() == "^tagName")
    }
}
