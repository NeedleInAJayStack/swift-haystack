import XCTest
import Haystack

final class ListTests: XCTestCase {
    func testJsonCoding() throws {
        let value: List = [
            true,
            "abc",
            Number(42, unit: "furloghs"),
            List([
                false,
                "xyz"
            ])
        ]
        let jsonString = #"[true,"abc",{"_kind":"number","val":42,"unit":"furloghs"},[false,"xyz"]]"#
        
        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(List.self, from: encodedData),
            value
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
                Number(42, unit: "furloghs"),
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
                Number(42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ]),
            List([
                true,
                "abc",
                Number(42, unit: "furloghs"),
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
                Number(42, unit: "furloghs"),
                List([
                    false,
                    "xyz"
                ])
            ]),
            List([
                true,
                "abc",
                Number(42, unit: "furloghs"),
                List([
                    true,
                    "xyz"
                ])
            ])
        )
    }
    
    func testCollection() {
        let list: List = [
            true,
            "abc",
            Number(42, unit: "furloghs"),
            List([true, "xyz"])
        ]
        
        // Test index access
        XCTAssertEqual(list[0] as? Bool, true)
        XCTAssertEqual(list[1] as? String, "abc")
        XCTAssertEqual((list[2] as? Number), Number(42, unit: "furloghs"))
        XCTAssertEqual((list[3] as? List), [true, "xyz"])
        
        // Test loop
        for (i, element) in list.enumerated() {
            switch i {
            case 0: XCTAssertEqual(element as? Bool, true)
            case 1: XCTAssertEqual(element as? String, "abc")
            case 2: XCTAssertEqual((element as? Number), Number(42, unit: "furloghs"))
            case 3: XCTAssertEqual((element as? List), [true, "xyz"])
            default: break
            }
        }
    }
}
