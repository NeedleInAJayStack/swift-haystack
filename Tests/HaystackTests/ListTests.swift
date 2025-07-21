import Foundation
import Haystack
import Testing

struct ListTests {
    @Test func jsonCoding() throws {
        let value: List = [
            true,
            "abc",
            Number(42, unit: "furloghs"),
            List([
                false,
                "xyz",
            ]),
        ]
        let jsonString = #"[true,"abc",{"_kind":"number","val":42,"unit":"furloghs"},[false,"xyz"]]"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(List.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(List.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(
            List([
                true,
                "abc",
                Number(42, unit: "furloghs"),
                List([
                    false,
                    "xyz",
                ]),
            ]).toZinc()
                ==
                #"[T, "abc", 42furloghs, [F, "xyz"]]"#
        )
    }

    @Test func equatable() {
        // Test basic
        #expect(List(["a"]) == List(["a"]))
        #expect(List(["a"]) != List(["b"]))

        // Test element count matters
        #expect(List(["a", "a"]) != List(["a"]))
        #expect(List(["a"]) != List(["a", "a"]))

        // Test order matters
        #expect(List(["a", "b"]) != List(["b", "a"]))

        // Test nested
        #expect(
            List([
                true,
                "abc",
                Number(42, unit: "furloghs"),
                List([
                    false,
                    "xyz",
                ]),
            ]) ==
                List([
                    true,
                    "abc",
                    Number(42, unit: "furloghs"),
                    List([
                        false,
                        "xyz",
                    ]),
                ])
        )
        #expect(
            List([
                true,
                "abc",
                Number(42, unit: "furloghs"),
                List([
                    false,
                    "xyz",
                ]),
            ]) !=
                List([
                    true,
                    "abc",
                    Number(42, unit: "furloghs"),
                    List([
                        true,
                        "xyz",
                    ]),
                ])
        )
    }

    @Test func collection() {
        let list: List = [
            true,
            "abc",
            Number(42, unit: "furloghs"),
            List([true, "xyz"]),
        ]

        // Test index access
        #expect(list[0] as? Bool == true)
        #expect(list[1] as? String == "abc")
        #expect((list[2] as? Number) == Number(42, unit: "furloghs"))
        #expect((list[3] as? List) == [true, "xyz"])

        // Test loop
        for (i, element) in list.enumerated() {
            switch i {
            case 0: #expect(element as? Bool == true)
            case 1: #expect(element as? String == "abc")
            case 2: #expect((element as? Number) == Number(42, unit: "furloghs"))
            case 3: #expect((element as? List) == [true, "xyz"])
            default: break
            }
        }
    }
}
