import XCTest
import Haystack

final class RefTests: XCTestCase {
    func testInit() throws {
        try XCTAssertThrowsError(Ref("123 abc"))
        try XCTAssertThrowsError(Ref("123$abc"))
        try XCTAssertThrowsError(Ref("123%abc"))
    }
    
    func testJsonCoding() throws {
        let value = try Ref("123-abc", dis: "Name")
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
    
    func testToZinc() throws {
        XCTAssertEqual(
            try Ref("123-abc", dis: "Name").toZinc(),
            "@123-abc Name"
        )
        XCTAssertEqual(
            try Ref("123-abc").toZinc(),
            "@123-abc"
        )
    }
}
