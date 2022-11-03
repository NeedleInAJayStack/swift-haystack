import XCTest
import Haystack

final class RefTests: XCTestCase {
    func testJsonCoding() throws {
        let value = Ref(val: "123-abc", dis: "Name")
        let jsonString = #"{"_kind":"ref","val":"123-abc","dis":"Name"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Ref.self, from: decodedData),
            value
        )
    }
}
