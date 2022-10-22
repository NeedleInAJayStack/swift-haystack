import XCTest
@testable import Haystack

final class StringTests: XCTestCase {
    func testToZinc() throws {
        XCTAssertEqual("hello".toZinc(), #""hello""#)
        XCTAssertEqual("_ \\ \" \n \r \t \u{0011} _".toZinc(), #""_ \\ \" \n \r \t \u0011 _""#)
        XCTAssertEqual("\u{0abc}".toZinc(), #""\u0abc""#)
    }
}
