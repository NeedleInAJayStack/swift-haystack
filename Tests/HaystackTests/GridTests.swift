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
            .addRow(["RTU-1", marker, Ref("153c-699a", dis: "HQ"), Date(year: 2005, month: 6, day: 1)])
            .addRow(["RTU-2", marker, Ref("153c-699b", dis: "Library"), Date(year: 1997, month: 7, day: 12)])
            .toGrid()
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
    
    func testJsonCoding_empty() throws {
        let value = GridBuilder().toGrid()
        let jsonString = #"{"_kind":"grid","meta":{"ver":"3.0"},"cols":[{"name":"empty"}],"rows":[]}"#
        
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
    
    func testToZinc() throws {
        XCTAssertEqual(
            try GridBuilder()
                .setMeta(["foo": "bar"])
                .addCol(name: "dis", meta: ["dis": "Equip Name"])
                .addCol(name: "equip")
                .addCol(name: "siteRef")
                .addCol(name: "installed")
                .addRow(["RTU-1", marker, Ref("153c-699a", dis: "HQ"), Date(year: 2005, month: 6, day: 1)])
                .addRow(["RTU-2", marker, Ref("153c-699b", dis: "Library"), Date(year: 1997, month: 7, day: 12)])
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
            .addRow(["RTU-1", marker, Ref("153c-699a", dis: "HQ"), true])
            .addRow(["RTU-2", marker, Ref("153c-699b", dis: "Library"), false])
        
        let builder2 = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["RTU-1", marker, Ref("153c-699a", dis: "HQ"), false])
            .addRow(["RTU-2", marker, Ref("153c-699b", dis: "Library"), false])
        
        
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
