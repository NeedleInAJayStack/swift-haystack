import XCTest
import Haystack

final class XStrTests: XCTestCase {
    func testInit() throws {
        try XCTAssertThrowsError(XStr(type: "span", val: "today"))
        try XCTAssertThrowsError(XStr(type: "Span range", val: "today"))
        try XCTAssertThrowsError(XStr(type: "Span!", val: "today"))
    }
    
    func testJsonCoding() throws {
        let value = try XStr(type: "Span", val: "today")
        let jsonString = #"{"_kind":"xstr","type":"Span","val":"today"}"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(XStr.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            try XStr(type: "Span", val: "today").toZinc(),
            #"Span("today")"#
        )
    }
}
