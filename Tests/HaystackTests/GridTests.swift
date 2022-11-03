import XCTest
import Haystack

final class GridTests: XCTestCase {
    func testJsonCoding() throws {
        let date1 = try XCTUnwrap(ISO8601DateFormatter().date(from:"2005-06-01T00:00:00Z"))
        let date2 = try XCTUnwrap(ISO8601DateFormatter().date(from:"1997-07-12T00:00:00Z"))
        
        let value: Grid = Grid(
            meta: ["ver": "3.0", "foo": "bar"],
            cols: [
                .init(name: "dis", meta: ["dis": "Equip Name"]),
                .init(name: "equip"),
                .init(name: "siteRef"),
                .init(name: "installed")
            ],
            rows: [
                [
                    "dis": "RTU-1",
                    "equip": marker,
                    "siteRef": Ref(val: "153c-699a", dis: "HQ"),
                    "installed": Date(date: date1)
                ],
                [
                    "dis": "RTU-2",
                    "equip": marker,
                    "siteRef": Ref(val: "153c-699b", dis: "Library"),
                    "installed": Date(date: date2)
                ],
            ]
        )
        let jsonString = #"{"_kind":"grid","meta":{"ver":"3.0","foo":"bar"},"cols":[{"name":"dis","meta":{"dis":"Equip Name"}},{"name":"equip"},{"name":"siteRef"},{"name":"installed"}],"rows":[{"dis":"RTU-1","equip":{"_kind":"marker"},"siteRef":{"_kind":"ref","val":"153c-699a","dis":"HQ"},"installed":{"_kind":"date","val":"2005-06-01"}},{"dis": "RTU-2","equip":{"_kind":"marker"},"siteRef":{"_kind":"ref","val":"153c-699b","dis":"Library"},"installed":{"_kind":"date","val":"1997-07-12"}}]}"#
        
        // Since Swift doesn't guarantee JSON attribute ordering, we must round-trip this instead of
        // comparing to the string
        let encodedData = try JSONEncoder().encode(value)
        XCTAssertEqual(
            try JSONDecoder().decode(Grid.self, from: encodedData),
            value
        )
        
        let decodedData = try XCTUnwrap(jsonString.data(using: .utf8))
        XCTAssertEqual(
            try JSONDecoder().decode(Grid.self, from: decodedData),
            value
        )
    }
    
    func testEquatable() {
        // Test basic
        XCTAssertEqual (
            Grid(
                meta: ["ver": "3.0", "foo": "bar"],
                cols: [
                    .init(name: "dis", meta: ["dis": "Equip Name"]),
                    .init(name: "equip"),
                    .init(name: "siteRef"),
                    .init(name: "installed")
                ],
                rows: [
                    [
                        "dis": "RTU-1",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699a", dis: "HQ"),
                        "managed": true
                    ],
                    [
                        "dis": "RTU-2",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699b", dis: "Library"),
                        "managed": false
                    ],
                ]
            ),
            Grid(
                meta: ["ver": "3.0", "foo": "bar"],
                cols: [
                    .init(name: "dis", meta: ["dis": "Equip Name"]),
                    .init(name: "equip"),
                    .init(name: "siteRef"),
                    .init(name: "installed")
                ],
                rows: [
                    [
                        "dis": "RTU-1",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699a", dis: "HQ"),
                        "managed": true
                    ],
                    [
                        "dis": "RTU-2",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699b", dis: "Library"),
                        "managed": false
                    ],
                ]
            )
        )
        XCTAssertNotEqual (
            Grid(
                meta: ["ver": "3.0", "foo": "bar"],
                cols: [
                    .init(name: "dis", meta: ["dis": "Equip Name"]),
                    .init(name: "equip"),
                    .init(name: "siteRef"),
                    .init(name: "installed")
                ],
                rows: [
                    [
                        "dis": "RTU-1",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699a", dis: "HQ"),
                        "managed": false
                    ],
                    [
                        "dis": "RTU-2",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699b", dis: "Library"),
                        "managed": false
                    ],
                ]
            ),
            Grid(
                meta: ["ver": "3.0", "foo": "bar"],
                cols: [
                    .init(name: "dis", meta: ["dis": "Equip Name"]),
                    .init(name: "equip"),
                    .init(name: "siteRef"),
                    .init(name: "installed")
                ],
                rows: [
                    [
                        "dis": "RTU-1",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699a", dis: "HQ"),
                        "managed": true
                    ],
                    [
                        "dis": "RTU-2",
                        "equip": marker,
                        "siteRef": Ref(val: "153c-699b", dis: "Library"),
                        "managed": false
                    ],
                ]
            )
        )
    }
}
