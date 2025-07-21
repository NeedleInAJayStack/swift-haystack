import Foundation
import Haystack
import Testing

struct MarkerTests {
    @Test func jsonCoding() throws {
        let value = marker
        let jsonString = #"{"_kind":"marker"}"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Marker.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(marker.toZinc() == "M")
    }
}
