import Foundation
import Haystack
import Testing

struct NumberTests {
    @Test func isInt() throws {
        #expect(Number(5).isInt)
        #expect(!Number(5.5).isInt)
        #expect(Number(-1).isInt)
        #expect(!Number(-1.99999).isInt)
    }

    @Test func jsonCoding() throws {
        let value = Number(12.199, unit: "kWh")
        let jsonString = #"{"_kind":"number","val":12.199,"unit":"kWh"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Number.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Number.self, from: decodedData) == value)
    }

    @Test func jsonCoding_noUnit() throws {
        let value = Number(3.899)
        let jsonString = #"3.899"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Number.self, from: decodedData) == value)
    }

    @Test func jsonCoding_infinity() throws {
        let value = Number(.infinity)
        let jsonString = #"{"_kind":"number","val":"INF"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Number.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Number.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(Number(12.199, unit: "kWh").toZinc() == "12.199kWh")
        #expect(Number(1, unit: "kWh/ft\u{00b2}").toZinc() == #"1kWh/ft\u00b2"#)
        #expect(Number(3.899).toZinc() == "3.899")
        #expect(Number(4).toZinc() == "4")
        #expect(Number.infinity.toZinc() == "INF")
        #expect(Number.negativeInfinity.toZinc() == "-INF")
        #expect(Number.nan.toZinc() == "NaN")
    }
}
