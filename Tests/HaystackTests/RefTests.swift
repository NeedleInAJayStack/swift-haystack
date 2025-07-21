import Foundation
import Haystack
import Testing

struct RefTests {
    @Test func testInit() throws {
        #expect(throws: RefError.self) { try Ref("123 abc") }
        #expect(throws: RefError.self) { try Ref("123$abc") }
        #expect(throws: RefError.self) { try Ref("123%abc") }
    }

    @Test func jsonCoding() throws {
        let value = try Ref("123-abc", dis: "Name")
        let jsonString = #"{"_kind":"ref","val":"123-abc","dis":"Name"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Ref.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Ref.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(try Ref("123-abc", dis: "Name").toZinc() == "@123-abc Name")
        #expect(try Ref("123-abc").toZinc() == "@123-abc")
    }
}
