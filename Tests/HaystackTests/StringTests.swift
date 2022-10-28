import XCTest
@testable import Haystack

final class StringTests: XCTestCase {
    func testJsonEncode() throws {
        let encoder = JSONEncoder()
        
        let stringData = try encoder.encode("hello")
        XCTAssertEqual(
            String(data: stringData, encoding: .utf8),
            #""hello""#
        )
    }
    
    func testJsonDecode() throws {
        let decoder = JSONDecoder()
        
        let stringData = try XCTUnwrap(#""hello""#.data(using: .utf8))
        XCTAssertEqual(
            try decoder.decode(String.self, from: stringData),
            "hello"
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual("hello".toZinc(), #""hello""#)
        XCTAssertEqual("_ \\ \" \n \r \t \u{0011} _".toZinc(), #""_ \\ \" \n \r \t \u0011 _""#)
        XCTAssertEqual("\u{0abc}".toZinc(), #""\u0abc""#)
    }
}
