import Haystack
import HaystackServerVapor
import Testing
import VaporTesting

struct HaystackServerVaporTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            app.haystack = HaystackAPIMock()
            try app.register(collection: HaystackRouteCollection())
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test func get() async throws {
        try await withApp { app in
            let responseGrid = try GridBuilder()
                .addCols(names: ["id", "foo"])
                .addRow([Haystack.Ref("a"), Marker.val])
                .addRow([Haystack.Ref("b"), Marker.val])
                .toGrid()

            // Test zinc encoding
            try await app.test(
                .GET,
                "/read?id=[@a,@b]",
                headers: [
                    HTTPHeaders.Name.accept.description: HTTPMediaType.zinc.description,
                ]
            ) { res in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .zinc)
                #expect(res.body.string == responseGrid.toZinc())
            }

            // Test JSON encoding
            try await app.test(
                .GET,
                "/read?id=[@a,@b]",
                headers: [
                    HTTPHeaders.Name.accept.description: HTTPMediaType.json.description,
                ]
            ) { res in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .json)
                try #expect(res.content.decode(Grid.self) == responseGrid)
            }
        }
    }

    @Test func getBadQuery() async throws {
        try await withApp { app in
            try await app.test(
                .GET,
                "/read?id=[a,b]" // Invalid because expecting Ref, not String
            ) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func post() async throws {
        try await withApp { app in
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
            try await app.test(
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
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .zinc)
                #expect(res.body.string == responseGrid.toZinc())
            }

            // Test JSON encoding
            try await app.test(
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
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .json)
                try #expect(res.content.decode(Grid.self) == responseGrid)
            }
        }
    }

    @Test func postBadQuery() async throws {
        try await withApp { app in
            let requestGrid = try GridBuilder()
                .addCol(name: "id")
                .addRow(["a"]) // Invalid because expecting Ref, not String
                .addRow(["b"])
                .toGrid()

            // Test zinc encoding
            try await app.test(
                .POST,
                "/read",
                body: .init(string: requestGrid.toZinc()),
                beforeRequest: { req in
                    req.headers.contentType = .zinc
                }
            ) { res in
                #expect(res.status == .badRequest)
            }

            // Test JSON encoding
            try await app.test(
                .POST,
                "/read",
                beforeRequest: { req in
                    req.headers.contentType = .json
                    try req.content.encode(requestGrid)
                }
            ) { res in
                #expect(res.status == .badRequest)
            }
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
