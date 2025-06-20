import Foundation
import Haystack
import Testing

struct CoordTests {
    @Test func testInit() throws {
        #expect(throws: CoordError.self) { try Coord(latitude: -91, longitude: 0) }
        #expect(throws: CoordError.self) { try Coord(latitude: 91, longitude: 0) }
        #expect(throws: CoordError.self) { try Coord(latitude: 0, longitude: -181) }
        #expect(throws: CoordError.self) { try Coord(latitude: 0, longitude: 181) }
    }

    @Test func jsonCoding() throws {
        let value = try Coord(latitude: 40, longitude: -111.84)
        let jsonString = #"{"_kind":"coord","lat":40,"lng":-111.84}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Coord.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Coord.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(try Coord(latitude: 40, longitude: -111.84).toZinc() == "C(40.0,-111.84)")
    }
}
