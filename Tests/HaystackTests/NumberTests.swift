import XCTest
import Haystack

final class NumberTests: XCTestCase {
    func testIsInt() throws {
        XCTAssertTrue(Number(5).isInt)
        XCTAssertFalse(Number(5.5).isInt)
        XCTAssertTrue(Number(-1).isInt)
        XCTAssertFalse(Number(-1.99999).isInt)
    }
    
    func testJsonCoding() throws {
        let value = Number(12.199, unit: "kWh")
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
        let value = Number(3.899)
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
    
    func testJsonCoding_infinity() throws {
        let value = Number(.infinity)
        let jsonString = #"{"_kind":"number","val":"INF"}"#

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
    
    func testToZinc() throws {
        XCTAssertEqual(
            Number(12.199, unit: "kWh").toZinc(),
            "12.199kWh"
        )
        XCTAssertEqual(
            Number(1, unit: "kWh/ft\u{00b2}").toZinc(),
            #"1kWh/ft\u00b2"#
        )
        XCTAssertEqual(
            Number(3.899).toZinc(),
            "3.899"
        )
        XCTAssertEqual(
            Number(4).toZinc(),
            "4"
        )
        XCTAssertEqual(
            Number.infinity.toZinc(),
            "INF"
        )
        XCTAssertEqual(
            Number.negativeInfinity.toZinc(),
            "-INF"
        )
        XCTAssertEqual(
            Number.nan.toZinc(),
            "NaN"
        )
    }
}
