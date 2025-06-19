import Foundation
import Haystack
import Testing

struct StringTests {
    @Test func jsonCoding() throws {
        let value = "hello"
        let jsonString = #""hello""#

        let encodedData = try JSONEncoder().encode(value)
        #expect(String(data: encodedData, encoding: .utf8) == jsonString)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(String.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect("hello".toZinc() == #""hello""#)
        #expect("_ \\ \" \n \r \t \u{0011} _".toZinc() == #""_ \\ \" \n \r \t \u0011 _""#)
        #expect("\u{0abc}".toZinc() == #""\u0abc""#)
    }
}
