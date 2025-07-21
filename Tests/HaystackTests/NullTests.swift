import Foundation
import Haystack
import Testing

struct NullTests {
    @Test func jsonCoding() throws {
        let value = null
        let jsonString = #"null"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Null.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(null.toZinc() == "N")
    }
}
