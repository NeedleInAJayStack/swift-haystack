import Haystack
import HaystackServerVapor
import XCTest
import XCTVapor

final class HaystackServerVaporTests: XCTestCase {
    func testGet() throws {
        let app = Application(.testing)
        app.haystack = HaystackAPIMock()
        try app.register(collection: HaystackRouteCollection())
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
                HTTPHeaders.Name.accept.description: HTTPMediaType.zinc.description,
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
                HTTPHeaders.Name.accept.description: HTTPMediaType.json.description,
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
        app.haystack = HaystackAPIMock()
        try app.register(collection: HaystackRouteCollection())
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
        app.haystack = HaystackAPIMock()
        try app.register(collection: HaystackRouteCollection())
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
                HTTPHeaders.Name.accept.description: HTTPMediaType.zinc.description,
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
                HTTPHeaders.Name.accept.description: HTTPMediaType.json.description,
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
        app.haystack = HaystackAPIMock()
        try app.register(collection: HaystackRouteCollection())
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

struct HaystackAPIMock: Haystack.API, Sendable {
    func close() async throws {}

    func about() async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func defs(filter _: String?, limit _: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func libs(filter _: String?, limit _: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func ops(filter _: String?, limit _: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func filetypes(filter _: String?, limit _: Haystack.Number?) async throws -> Haystack.Grid {
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

    func read(filter _: String, limit _: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func nav(navId _: Haystack.Ref?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func hisRead(id _: Haystack.Ref, range _: Haystack.HisReadRange) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func hisWrite(id _: Haystack.Ref, items _: [Haystack.HisItem]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func pointWrite(id _: Haystack.Ref, level _: Haystack.Number, val _: any Haystack.Val, who _: String?, duration _: Haystack.Number?) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func pointWriteStatus(id _: Haystack.Ref) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchSubCreate(watchDis _: String, lease _: Haystack.Number?, ids _: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchSubAdd(watchId _: String, lease _: Haystack.Number?, ids _: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchUnsubRemove(watchId _: String, ids _: [Haystack.Ref]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchUnsubDelete(watchId _: String) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func watchPoll(watchId _: String, refresh _: Bool) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func invokeAction(id _: Haystack.Ref, action _: String, args _: [String: any Haystack.Val]) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }

    func eval(expression _: String) async throws -> Haystack.Grid {
        return GridBuilder().toGrid()
    }
}
