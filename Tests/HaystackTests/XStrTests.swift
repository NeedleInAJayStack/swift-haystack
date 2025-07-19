import Foundation
import Haystack
import Testing

struct XStrTests {
    @Test func testInit() throws {
        #expect(throws: (any Error).self) { try XStr(type: "span", val: "today") }
        #expect(throws: (any Error).self) { try XStr(type: "Span range", val: "today") }
        #expect(throws: (any Error).self) { try XStr(type: "Span!", val: "today") }
    }

    @Test func jsonCoding() throws {
        let value = try XStr(type: "Span", val: "today")
        let jsonString = #"{"_kind":"xstr","type":"Span","val":"today"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(XStr.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(XStr.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(try XStr(type: "Span", val: "today").toZinc() == #"Span("today")"#)
    }
}
