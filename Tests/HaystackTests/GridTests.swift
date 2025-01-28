import XCTest
import Haystack

final class GridTests: XCTestCase {
    func testJsonCoding() throws {
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
    
    func testJsonCoding_empty() throws {
        let value = GridBuilder().toGrid()
        let jsonString = #"{"_kind":"grid","meta":{"ver":"3.0"},"cols":[{"name":"empty"}],"rows":[]}"#
        
        // Must encode/decode b/c JSON ordering is not deterministic
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
    
    func testToZinc() throws {
        XCTAssertEqual(
            try GridBuilder()
                .setMeta(["foo": "bar"])
                .addCol(name: "dis", meta: ["dis": "Equip Name"])
                .addCol(name: "equip")
                .addCol(name: "siteRef")
                .addCol(name: "installed")
                .addRow(["dis": "RTU-1", "equip": marker, "siteRef": Ref("153c-699a", dis: "HQ"), "installed": Date(year: 2005, month: 6, day: 1)])
                .addRow(["dis": "RTU-2", "equip": marker, "siteRef": Ref("153c-699b", dis: "Library"), "installed": Date(year: 1997, month: 7, day: 12)])
                .toGrid()
                .toZinc(),
            """
            ver:"3.0" foo:"bar"
            dis dis:"Equip Name", equip, siteRef, installed
            "RTU-1", M, @153c-699a HQ, 2005-06-01
            "RTU-2", M, @153c-699b Library, 1997-07-12
            """
        )
        
        // Test empty grid
        XCTAssertEqual(
            GridBuilder()
                .toGrid()
                .toZinc(),
            """
            ver:"3.0"
            empty
            
            """
        )
    }
    
    func testEquatable() throws {
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
        XCTAssertEqual (
            builder1.toGrid(),
            builder1.toGrid()
        )
        XCTAssertNotEqual (
            builder1.toGrid(),
            builder2.toGrid()
        )
    }
}
