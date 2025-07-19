import Foundation
import Haystack
import Testing

struct NATests {
    @Test func jsonCoding() throws {
        let value = na
        let jsonString = #"{"_kind":"na"}"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(NA.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(na.toZinc() == "NA")
    }
}
