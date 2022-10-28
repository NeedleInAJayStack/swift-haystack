import XCTest
@testable import Haystack

final class BoolTests: XCTestCase {
    func testJsonEncode() throws {
        let encoder = JSONEncoder()
        
        let trueData = try encoder.encode(true)
        XCTAssertEqual(
            String(data: trueData, encoding: .utf8),
            "true"
        )
        
        let falseData = try encoder.encode(false)
        XCTAssertEqual(
            String(data: falseData, encoding: .utf8),
            "false"
        )
    }
    
    func testJsonDecode() throws {
        let decoder = JSONDecoder()
        
        let trueData = try XCTUnwrap("true".data(using: .utf8))
        XCTAssertEqual(
            try decoder.decode(Bool.self, from: trueData),
            true
        )
        
        let falseData = try XCTUnwrap("false".data(using: .utf8))
        XCTAssertEqual(
            try decoder.decode(Bool.self, from: falseData),
            false
        )
    }
    
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
