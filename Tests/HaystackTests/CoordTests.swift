import XCTest
import Haystack

final class CoordTests: XCTestCase {
    func testInit() throws {
        try XCTAssertThrowsError(Coord(latitude: -91, longitude: 0))
        try XCTAssertThrowsError(Coord(latitude: 91, longitude: 0))
        try XCTAssertThrowsError(Coord(latitude: 0, longitude: -181))
        try XCTAssertThrowsError(Coord(latitude: 0, longitude: 181))
    }
    
    func testJsonCoding() throws {
        let value = try Coord(latitude: 40, longitude: -111.84)
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
            try Coord(latitude: 40, longitude: -111.84).toZinc(),
            "C(40.0,-111.84)"
        )
    }
}
