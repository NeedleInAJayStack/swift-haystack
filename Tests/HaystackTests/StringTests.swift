import Haystack
import XCTest

final class StringTests: XCTestCase {
    func testJsonCoding() throws {
        let value = "hello"
        let jsonString = #""hello""#

        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )

        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(String.self, from: decodedData),
            value
        )
    }

    func testToZinc() throws {
        XCTAssertEqual("hello".toZinc(), #""hello""#)
        XCTAssertEqual("_ \\ \" \n \r \t \u{0011} _".toZinc(), #""_ \\ \" \n \r \t \u0011 _""#)
        XCTAssertEqual("\u{0abc}".toZinc(), #""\u0abc""#)
    }
}
