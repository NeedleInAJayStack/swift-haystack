import Haystack
import HaystackServerVapor
import XCTest
import XCTVapor

final class HaystackServerVaporTests: XCTestCase {
    func testGet() throws {
        let app = Application(.testing)
        try app.register(collection: HaystackRouteCollection(delegate: HaystackAPIMock()))
        defer { app.shutdown() }

        let responseGrid = try GridBuilder()
            .addCols(names: ["id", "foo"])
            .addRow([Haystack.Ref("a"), Marker.val])
            .addRow([Haystack.Ref("b"), Marker.val])
            .toGrid()

        // Test zinc encoding
        try app.test(
            .GET,
            "/read?id=[@a,@b]",
            headers: [
                HTTPHeaders.Name.accept.description: HTTPMediaType.zinc.description
            ]
         ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .zinc)
            XCTAssertEqual(
                res.body.string,
                responseGrid.toZinc()
            )
        }

        // Test JSON encoding
        try app.test(
            .GET,
            "/read?id=[@a,@b]",
            headers: [
                HTTPHeaders.Name.accept.description: HTTPMediaType.json.description
            ]
         ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .json)
            try XCTAssertEqual(
                res.content.decode(Grid.self),
                responseGrid
            )
        }
    }

    func testGetBadQuery() throws {
        let app = Application(.testing)
        try app.register(collection: HaystackRouteCollection(delegate: HaystackAPIMock()))
        defer { app.shutdown() }

        try app.test(
            .GET,
            "/read?id=[a,b]" // Invalid because expecting Ref, not String
         ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testPost() throws {
        let app = Application(.testing)
        try app.register(collection: HaystackRouteCollection(delegate: HaystackAPIMock()))
        defer { app.shutdown() }

        let requestGrid = try GridBuilder()
            .addCol(name: "id")
            .addRow([Haystack.Ref("a")])
            .addRow([Haystack.Ref("b")])
            .toGrid()

        let responseGrid = try GridBuilder()
            .addCols(names: ["id", "foo"])
            .addRow([Haystack.Ref("a"), Marker.val])
            .addRow([Haystack.Ref("b"), Marker.val])
            .toGrid()

        // Test zinc encoding
        try app.test(
            .POST,
            "/read",
            headers: [
                HTTPHeaders.Name.accept.description: HTTPMediaType.zinc.description
            ],
            body: .init(string: requestGrid.toZinc()),
            beforeRequest: { req in
                req.headers.contentType = .zinc
            }
        ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .zinc)
            XCTAssertEqual(
                res.body.string,
                responseGrid.toZinc()
            )
        }

        // Test JSON encoding
        try app.test(
            .POST,
            "/read",
            headers: [
                HTTPHeaders.Name.accept.description: HTTPMediaType.json.description
            ],
            beforeRequest: { req in
                req.headers.contentType = .json
                try req.content.encode(requestGrid)
            }
        ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .json)
            try XCTAssertEqual(
                res.content.decode(Grid.self),
                responseGrid
            )
        }
    }

    func testPostBadQuery() throws {
        let app = Application(.testing)
        try app.register(collection: HaystackRouteCollection(delegate: HaystackAPIMock()))
        defer { app.shutdown() }

        let requestGrid = try GridBuilder()
            .addCol(name: "id")
            .addRow(["a"]) // Invalid because expecting Ref, not String
            .addRow(["b"])
            .toGrid()

        // Test zinc encoding
        try app.test(
            .POST,
            "/read",
            body: .init(string: requestGrid.toZinc()),
            beforeRequest: { req in
                req.headers.contentType = .zinc
            }
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        // Test JSON encoding
        try app.test(
            .POST,
            "/read",
            beforeRequest: { req in
                req.headers.contentType = .json
                try req.content.encode(requestGrid)
            }
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
}

struct HaystackAPIMock: Haystack.API {
    func close() async throws {
        return
    }

    func about() async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func defs(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func libs(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func ops(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func filetypes(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func read(ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        let gb = GridBuilder()
        try gb.addCol(name: "id")
        try gb.addCol(name: "foo")
        for id in ids {
            try gb.addRow([id, Marker.val])
        }
        return gb.toGrid()
    }

    func read(filter: String, limit: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func nav(navId: Haystack.Ref?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func hisRead(id: Haystack.Ref, range: Haystack.HisReadRange) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func hisWrite(id: Haystack.Ref, items: [Haystack.HisItem]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func pointWrite(id: Haystack.Ref, level: Haystack.Number, val: any Haystack.Val, who: String?, duration: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func pointWriteStatus(id: Haystack.Ref) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchSubCreate(watchDis: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchSubAdd(watchId: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchUnsubRemove(watchId: String, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchUnsubDelete(watchId: String) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchPoll(watchId: String, refresh: Bool) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func invokeAction(id: Haystack.Ref, action: String, args: [String : any Haystack.Val]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func eval(expression: String) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }
}
