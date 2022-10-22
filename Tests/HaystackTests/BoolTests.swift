import XCTest
@testable import Haystack

final class BoolTests: XCTestCase {
    func testToZinc() throws {
        XCTAssertEqual(false.toZinc(), "F")
        XCTAssertEqual(true.toZinc(), "T")
    }
    
    func testComparable() throws {
        XCTAssertFalse(false < false)
        XCTAssertTrue(false < true)
        XCTAssertFalse(true < false)
        XCTAssertFalse(true < true)
    }
}
