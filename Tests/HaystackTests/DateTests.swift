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
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
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
