import Foundation
import Haystack
import Testing

struct RemoveTests {
    @Test func jsonCoding() throws {
        let value = remove
        let jsonString = #"{"_kind":"remove"}"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Remove.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(remove.toZinc() == "R")
    }
}
