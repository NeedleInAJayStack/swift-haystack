import XCTest
import Haystack

final class CoordTests: XCTestCase {
    func testInit() throws {
        try XCTAssertThrowsError(Coord(lat: -91, lng: 0))
        try XCTAssertThrowsError(Coord(lat: 91, lng: 0))
        try XCTAssertThrowsError(Coord(lat: 0, lng: -181))
        try XCTAssertThrowsError(Coord(lat: 0, lng: 181))
    }
    
    func testJsonCoding() throws {
        let value = try Coord(lat: 40, lng: -111.84)
        let jsonString = #"{"_kind":"coord","lat":40,"lng":-111.84}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Coord.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            try Coord(lat: 40, lng: -111.84).toZinc(),
            "C(40.0,-111.84)"
        )
    }
}
