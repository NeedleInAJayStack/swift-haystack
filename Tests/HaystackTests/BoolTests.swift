import Foundation
import Haystack
import Testing

struct BoolTests {
    @Test func jsonCoding() throws {
        let value = true
        let jsonString = #"true"#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Bool.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(false.toZinc() == "F")
        #expect(true.toZinc() == "T")
    }

    @Test func comparable() throws {
        #expect((false < false) == false)
        #expect(false < true)
        #expect((true < false) == false)
        #expect((true < true) == false)
    }
}
