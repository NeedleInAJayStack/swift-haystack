import XCTest
import Haystack

final class GridTests: XCTestCase {
    func testJsonCoding() throws {
        let date1 = try XCTUnwrap(ISO8601DateFormatter().date(from:"2005-06-01T00:00:00Z"))
        let date2 = try XCTUnwrap(ISO8601DateFormatter().date(from:"1997-07-12T00:00:00Z"))
        
        let value = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "installed")
            .addRow(["RTU-1", marker, Ref(val: "153c-699a", dis: "HQ"), Date(date: date1)])
            .addRow(["RTU-2", marker, Ref(val: "153c-699b", dis: "Library"), Date(date: date2)])
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
    
    func testEquatable() throws {
        let builder1 = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["RTU-1", marker, Ref(val: "153c-699a", dis: "HQ"), true])
            .addRow(["RTU-2", marker, Ref(val: "153c-699b", dis: "Library"), false])
        
        let builder2 = try GridBuilder()
            .setMeta(["ver": "3.0", "foo": "bar"])
            .addCol(name: "dis", meta: ["dis": "Equip Name"])
            .addCol(name: "equip")
            .addCol(name: "siteRef")
            .addCol(name: "managed")
            .addRow(["RTU-1", marker, Ref(val: "153c-699a", dis: "HQ"), false])
            .addRow(["RTU-2", marker, Ref(val: "153c-699b", dis: "Library"), false])
        
        
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
