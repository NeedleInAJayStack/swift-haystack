import XCTest
import Haystack

final class MarkerTests: XCTestCase {
    func testJsonCoding() throws {
        let value = marker
        let jsonString = #"{"_kind":"marker"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Marker.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            marker.toZinc(),
            "M"
        )
    }
}
