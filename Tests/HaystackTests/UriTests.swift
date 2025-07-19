import Foundation
import Haystack
import Testing

struct UriTests {
    @Test func jsonCoding() throws {
        let value = Uri("http://en.wikipedia.org/")
        let jsonString = #"{"_kind":"uri","val":"http:\/\/en.wikipedia.org\/"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Uri.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Uri.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(Uri("http://en.wikipedia.org/").toZinc() == "`http://en.wikipedia.org/`")
    }
}
