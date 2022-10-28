import XCTest
@testable import Haystack

final class NumberTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Number(val: 12.199, unit: "kWh")
        let jsonString = #"{"_kind":"number","val":12.199,"unit":"kWh"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Number.self, from: decodedData),
            value
        )
    }
    
    func testJsonCoding_noUnit() throws {
        let value = Number(val: 3.899)
        let jsonString = #"3.899"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Number.self, from: decodedData),
            value
        )
    }
    
    // TODO: Fix this test
//    func testJsonCoding_infinity() throws {
//        let value = Number(val: .infinity)
//        let jsonString = #"{"_kind":"number","val":"INF"}"#
//
//        let encodedData = try JSONEncoder().encode(value)
//        XCTAssertEqual(
//            String(data: encodedData, encoding: .utf8),
//            jsonString
//        )
//
//        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
//        XCTAssertEqual(
//            try JSONDecoder().decode(Number.self, from: decodedData),
//            value
//        )
//    }
}
