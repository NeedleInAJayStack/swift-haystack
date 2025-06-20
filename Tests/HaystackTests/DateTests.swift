import Foundation
import Haystack
import Testing

struct DateTests {
    @Test func jsonCoding() throws {
        let value = try Date(
            year: 1991,
            month: 6,
            day: 7
        )
        let jsonString = #"{"_kind":"date","val":"1991-06-07"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Date.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Haystack.Date.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(
            try Date(
                year: 1991,
                month: 6,
                day: 7
            ).toZinc() == "1991-06-07"
        )
    }
}
