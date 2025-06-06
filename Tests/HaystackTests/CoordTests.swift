import Haystack
import XCTest

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

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Coord.self, from: encodedData),
            value
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
