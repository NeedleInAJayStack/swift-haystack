import Foundation
import Haystack
import Testing

struct DictTests {
    @Test func jsonCoding() throws {
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
        #expect(try JSONDecoder().decode(Dict.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Dict.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]).toZinc() ==
                // Keys are sorted alphabetically.
                #"{bool:T dict:{bool:F str:"xyz"} number:42furloghs str:"abc"}"#
        )
    }

    @Test func equatable() {
        // Test basic
        #expect(Dict(["a": "b"]) == Dict(["a": "b"]))
        #expect(Dict(["a": "a"]) != Dict(["a": "b"]))

        // Test element count matters
        #expect(
            Dict([
                "a": "a",
                "b": "b",
            ]) != Dict([
                "a": "a",
            ])
        )
        #expect(
            Dict([
                "a": "a",
            ]) != Dict([
                "a": "a",
                "b": "b",
            ])
        )

        // Test order does not matter
        #expect(
            Dict([
                "a": "a",
                "b": "b",
            ]) == Dict([
                "b": "b",
                "a": "a",
            ])
        )

        // Test nested
        #expect(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]) == Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ])
        )
        #expect(
            Dict([
                "bool": true,
                "str": "abc",
                "number": Number(42, unit: "furloghs"),
                "dict": Dict([
                    "bool": false,
                    "str": "xyz",
                ]),
            ]) != Dict([
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

    @Test func trap() throws {
        let dict: Dict = ["a": "abc", "b": null]

        #expect(throws: Never.self) { try dict.trap("a") }
        try #expect(dict.trap("a", as: String.self) == "abc")
        #expect(throws: (any Error).self) { try dict.trap("a", as: Number.self) }
        #expect(throws: (any Error).self) { try dict.trap("b") }
        #expect(throws: (any Error).self) { try dict.trap("c") }
    }

    @Test func get() throws {
        let dict: Dict = ["a": "abc", "b": null]

        try #expect(dict.get("a") != nil)
        try #expect(dict.get("a", as: String.self) == "abc")
        #expect(throws: ValError.self) { try dict.get("a", as: Number.self) }
        try #expect(dict.get("b") == nil)
        try #expect(dict.get("c") == nil)
    }

    @Test func collection() {
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
        #expect(dict["bool"] as? Bool == true)
        #expect(dict["str"] as? String == "abc")
        #expect(dict["number"] as? Number == Number(42, unit: "furloghs"))
        #expect(dict["dict"] as? Dict == ["bool": true, "str": "xyz"])

        // Test loop
        for (key, value) in dict {
            switch key {
            case "bool": #expect(value as? Bool == true)
            case "str": #expect(value as? String == "abc")
            case "number": #expect((value as? Number) == Number(42, unit: "furloghs"))
            case "dict": #expect((value as? Dict) == ["bool": true, "str": "xyz"])
            default: break
            }
        }
    }
}
