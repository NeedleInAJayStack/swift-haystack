import XCTest
@testable import Haystack

final class DictTests: XCTestCase {
    func testJsonCoding() throws {
        let value: Dict = [
            "bool": true,
            "str": "abc",
            "number": Number(val: 42, unit: "furloghs"),
            "dict": Dict([
                "bool": false,
                "str": "xyz"
            ])
        ]
        
        let jsonString = #"{"bool":true,"str":"abc","number":{"_kind":"number","val":42,"unit":"furloghs"},"dict":{"bool":false,"str":"xyz"}}"#
        
        // Since Swift doesn't guarantee JSON attribute ordering, we must round-trip this instead of
        // comparing to the string
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Dict.self, from: encodedData),
            value
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Dict.self, from: decodedData),
            value
        )
    }
    
    func testEquatable() {
        // Test basic
        XCTAssertEqual (
            Dict(["a":"b"]),
            Dict(["a":"b"])
        )
        XCTAssertNotEqual (
            Dict(["a":"a"]),
            Dict(["a":"b"])
        )
        
        // Test element count matters
        XCTAssertNotEqual (
            Dict([
                "a":"a",
                "b":"b",
            ]),
            Dict([
                "a":"a",
            ])
        )
        XCTAssertNotEqual (
            Dict([
                "a":"a",
            ]),
            Dict([
                "a":"a",
                "b":"b",
            ])
        )
        
        // Test order does not matter
        XCTAssertEqual (
            Dict([
                "a":"a",
                "b":"b",
            ]),
            Dict([
                "b":"b",
                "a":"a",
            ])
        )
        
        // Test nested
        XCTAssertEqual (
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(val: 42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz"
                ])
            ]),
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(val: 42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz"
                ])
            ])
        )
        XCTAssertNotEqual (
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(val: 42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz"
                ])
            ]),
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(val: 42, unit: "furloghs"),
                "dict": Dict([
                    "bool": true,
                    "str": "xyz"
                ])
            ])
        )
    }
}
