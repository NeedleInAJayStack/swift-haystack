import XCTest
import Haystack

final class DateTests: XCTestCase {
    func testJsonCoding() throws {
        let value = try Date(
            year: 1991,
            month: 6,
            day: 7
        )
        let jsonString = #"{"_kind":"date","val":"1991-06-07"}"#
        
        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Date.self, from: encodedData),
            value
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Date.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            try Date(
                year: 1991,
                month: 6,
                day: 7
            ).toZinc(),
            "1991-06-07"
        )
    }
}
