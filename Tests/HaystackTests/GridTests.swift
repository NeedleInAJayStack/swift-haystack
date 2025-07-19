import Foundation
import Haystack
import Testing

struct GridTests {
    @Test func jsonCoding() throws {
        let value = try GridBuilder()
            .setMeta(["foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "installed")
            .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "installed": Date(year: 2005, month: 6, day: 1)])
            .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "installed": Date(year: 1997, month: 7, day: 12)])
            .toGrid()
        let jsonString = #"{"_kind":"grid","meta":{"ver":"3.0","foo":"bar"},"cols":[{"name":"dis","meta":{"dis":"Equip Name"}},{"name":"equip"},{"name":"siteRef"},{"name":"installed"}],"rows":[{"dis":"RTU-1","equip":{"_kind":"marker"},"siteRef":{"_kind":"ref","val":"153c-699a","dis":"HQ"},"installed":{"_kind":"date","val":"2005-06-01"}},{"dis": "RTU-2","equip":{"_kind":"marker"},"siteRef":{"_kind":"ref","val":"153c-699b","dis":"Library"},"installed":{"_kind":"date","val":"1997-07-12"}}]}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Grid.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Grid.self, from: decodedData) == value)
    }

    @Test func jsonCoding_empty() throws {
        let value = GridBuilder().toGrid()
        let jsonString = #"{"_kind":"grid","meta":{"ver":"3.0"},"cols":[{"name":"empty"}],"rows":[]}"#

        // Must encode/decode b/c JSON ordering is not deterministic
        let encodedData = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Grid.self, from: encodedData) == value)

        let decodedData = try #require(jsonString.data(using: .utf8))
        #expect(try JSONDecoder().decode(Grid.self, from: decodedData) == value)
    }

    @Test func toZinc() throws {
        #expect(
            try GridBuilder()
                .setMeta(["foo": "bar"])
                .addCol(name: "dis", meta: ["dis": "Equip Name"])
                .addCol(name: "equip")
                .addCol(name: "siteRef")
                .addCol(name: "installed")
                .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "installed": Date(year: 2005, month: 6, day: 1)])
                .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "installed": Date(year: 1997, month: 7, day: 12)])
                .toGrid()
                .toZinc()
                ==
                """
                ver:"3.0" foo:"bar"
                dis dis:"Equip Name", equip, siteRef, installed
                "RTU-1", M, @153c-699a HQ, 2005-06-01
                "RTU-2", M, @153c-699b Library, 1997-07-12
                """
        )

        // Test empty grid
        #expect(
            GridBuilder()
                .toGrid()
                .toZinc()
                ==
                """
                ver:"3.0"
                empty

                """
        )
    }

    @Test func equatable() throws {
        let builder1 = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "managed": true])
            .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "managed": false])

        let builder2 = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "managed": false])
            .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "managed": false])

        // Test basic
        #expect(builder1.toGrid() == builder1.toGrid())
        #expect(builder1.toGrid() != builder2.toGrid())
    }

    @Test func collection() throws {
        let grid = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "managed": true])
            .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "managed": false])
            .toGrid()

        // Test index access
        #expect(try grid[0] == ["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "managed": true])
        #expect(try grid[1] == ["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "managed": false])
        #expect(grid[0]["dis"] as? String == "RTU-1")

        // Test loop
        for (i, row) in grid.enumerated() {
            switch i {
            case 0: #expect(try row == ["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "managed": true])
            case 1: #expect(try row == ["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "managed": false])
            default: break
            }
        }
    }
}
