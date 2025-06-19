import Foundation
import Haystack
import Testing

struct TimeTests {
    @Test func jsonCoding() throws {
        let value = try Time(hour: 7, minute: 7, second: 7, millisecond: 7)
        let jsonString = #"{"_kind":"time","val":"07:07:07.007"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Haystack.Time.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Haystack.Time.self, from: decodedData) == value)
    }

    @Test func jsonCoding_zeroMillis() throws {
        let value = try Time(hour: 7, minute: 7, second: 7, millisecond: 0)
        let jsonString = #"{"_kind":"time","val":"07:07:07"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Haystack.Time.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Haystack.Time.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(try Time(hour: 7, minute: 7, second: 7, millisecond: 0).toZinc() == "07:07:07")
        #expect(try Time(hour: 7, minute: 7, second: 7, millisecond: 7).toZinc() == "07:07:07.007")
    }
}
