import Haystack
import XCTest

final class DictTests: XCTestCase {
    func testJsonCoding() throws {
        let value: Dict = [
            "bool": true,
            "str": "abc",
            "number": Number(42, unit: "furloghs"),
            "dict": Dict([
                "bool": false,
                "str": "xyz",
            ]),
        ]

        let jsonString = #"{"bool":true,"str":"abc","number":{"_kind":"number","val":42,"unit":"furloghs"},"dict":{"bool":false,"str":"xyz"}}"#

        // Must encode/decode b/c JSON ordering is not deterministic
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

    func testToZinc() throws {
        XCTAssertEqual(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]).toZinc(),
            // Keys are sorted alphabetically.
            #"{bool:T dict:{bool:F str:"xyz"} number:42furloghs str:"abc"}"#
        )
    }

    func testEquatable() {
        // Test basic
        XCTAssertEqual(
            Dict(["a": "b"]),
            Dict(["a": "b"])
        )
        XCTAssertNotEqual(
            Dict(["a": "a"]),
            Dict(["a": "b"])
        )

        // Test element count matters
        XCTAssertNotEqual(
            Dict([
                "a": "a",
                "b": "b",
            ]),
            Dict([
                "a": "a",
            ])
        )
        XCTAssertNotEqual(
            Dict([
                "a": "a",
            ]),
            Dict([
                "a": "a",
                "b": "b",
            ])
        )

        // Test order does not matter
        XCTAssertEqual(
            Dict([
                "a": "a",
                "b": "b",
            ]),
            Dict([
                "b": "b",
                "a": "a",
            ])
        )

        // Test nested
        XCTAssertEqual(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]),
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ])
        )
        XCTAssertNotEqual(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]),
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": true,
                    "str": "xyz",
                ]),
            ])
        )
    }

    func testTrap() {
        let dict: Dict = ["a": "abc", "b": null]

        try XCTAssertNoThrow(dict.trap("a"))
        try XCTAssertEqual(dict.trap("a", as: String.self), "abc")
        try XCTAssertThrowsError(dict.trap("a", as: Number.self))
        try XCTAssertThrowsError(dict.trap("b"))
        try XCTAssertThrowsError(dict.trap("c"))
    }

    func testGet() {
        let dict: Dict = ["a": "abc", "b": null]

        try XCTAssertNotNil(dict.get("a"))
        try XCTAssertEqual(dict.get("a", as: String.self), "abc")
        try XCTAssertThrowsError(dict.get("a", as: Number.self))
        try XCTAssertNil(dict.get("b"))
        try XCTAssertNil(dict.get("c"))
    }

    func testCollection() {
        let dict: Dict = [
            "bool": true,
            "str": "abc",
            "number": Number(42, unit: "furloghs"),
            "dict": Dict([
                "bool": true,
                "str": "xyz",
            ]),
        ]

        // Test index access
        XCTAssertEqual(dict["bool"] as? Bool, true)
        XCTAssertEqual(dict["str"] as? String, "abc")
        XCTAssertEqual(dict["number"] as? Number, Number(42, unit: "furloghs"))
        XCTAssertEqual(dict["dict"] as? Dict, ["bool": true, "str": "xyz"])

        // Test loop
        for (key, value) in dict {
            switch key {
            case "bool": XCTAssertEqual(value as? Bool, true)
            case "str": XCTAssertEqual(value as? String, "abc")
            case "number": XCTAssertEqual((value as? Number), Number(42, unit: "furloghs"))
            case "dict": XCTAssertEqual((value as? Dict), ["bool": true, "str": "xyz"])
            default: break
            }
        }
    }
}
