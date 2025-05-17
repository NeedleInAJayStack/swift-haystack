import Haystack
import XCTest

final class TimeTests: XCTestCase {
    func testJsonCoding() throws {
        let value = try Time(hour: 7, minute: 7, second: 7, millisecond: 7)
        let jsonString = #"{"_kind":"time","val":"07:07:07.007"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: encodedData),
            value
        )

        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: decodedData),
            value
        )
    }

    func testJsonCoding_zeroMillis() throws {
        let value = try Time(hour: 7, minute: 7, second: 7, millisecond: 0)
        let jsonString = #"{"_kind":"time","val":"07:07:07"}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: encodedData),
            value
        )

        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Haystack.Time.self, from: decodedData),
            value
        )
    }

    func testToZinc() throws {
        XCTAssertEqual(
            try Time(hour: 7, minute: 7, second: 7, millisecond: 0).toZinc(),
            "07:07:07"
        )
        XCTAssertEqual(
            try Time(hour: 7, minute: 7, second: 7, millisecond: 7).toZinc(),
            "07:07:07.007"
        )
    }
}
