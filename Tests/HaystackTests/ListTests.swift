import XCTest
import Haystack

final class ListTests: XCTestCase {
    func testJsonCoding() throws {
        let value: List = [
            true,
            "abc",
            Number(val: 42, unit: "furloghs"),
            List([
                false,
                "xyz"
            ])
        ]
        let jsonString = #"[true,"abc",{"_kind":"number","val":42,"unit":"furloghs"},[false,"xyz"]]"#
        
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            jsonString
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(List.self, from: decodedData),
            value
        )
    }
    
    func testToZinc() throws {
        XCTAssertEqual(
            List([
                true,
                "abc",
                Number(val: 42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ]).toZinc(),
            #"[T, "abc", 42furloghs, [F, "xyz"]]"#
        )
    }
    
    func testEquatable() {
        // Test basic
        XCTAssertEqual (
            List(["a"]),
            List(["a"])
        )
        XCTAssertNotEqual (
            List(["a"]),
            List(["b"])
        )
        
        // Test element count matters
        XCTAssertNotEqual (
            List([
                "a",
                "a",
            ]),
            List([
                "a",
            ])
        )
        XCTAssertNotEqual (
            List([
                "a",
            ]),
            List([
                "a",
                "a",
            ])
        )
        
        // Test order matters
        XCTAssertNotEqual (
            List([
                "a",
                "b",
            ]),
            List([
                "b",
                "a",
            ])
        )
        
        // Test nested
        XCTAssertEqual (
            List([
                true,
                "abc",
                Number(val: 42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ]),
            List([
                true,
                "abc",
                Number(val: 42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ])
        )
        XCTAssertNotEqual (
            List([
                true,
                "abc",
                Number(val: 42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ]),
            List([
                true,
                "abc",
                Number(val: 42, unit: "furloghs"),
                List([
                    true,
                    "xyz"
                ])
            ])
        )
    }
}
