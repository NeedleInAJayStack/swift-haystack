import Foundation
import Haystack
import HaystackServer
import Testing

struct HaystackServerTests {
    @Test func about() async throws {
        let server = HaystackServer(
            recordStore: InMemoryRecordStore(),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )
        let response = try await server.about()
        let about = try #require(response.first)
        #expect(about["haystackVersion"] as? String != nil)
        #expect(about["tz"] as? String != nil)
        #expect(about["serverTime"] as? DateTime != nil)
        #expect(about["serverBootTime"] as? DateTime != nil)
        #expect(about["productName"] as? String == "swift-haystack")
        #expect(about["productUri"] as? Uri == Uri("https://github.com/NeedleInAJayStack/swift-haystack"))
        #expect(about["productVersion"] as? String != nil)
        #expect(about["vendorName"] as? String == "NeedleInAJayStack")
        #expect(about["vendorUri"] as? Uri == Uri("https://github.com/NeedleInAJayStack"))
    }

    @Test func defs() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("a"): ["id": Ref("a"), "def": Marker.val],
                Ref("b"): ["id": Ref("b"), "def": Marker.val, "foo": "bar"],
                Ref("c"): ["id": Ref("c")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Test no filter
        var grid = try await server.defs(filter: nil, limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])

        // Test filter
        grid = try await server.defs(filter: "foo", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == ["b"])

        // Test bad filter
        grid = try await server.defs(filter: "none", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == [])

        // Test limit
        grid = try await server.defs(filter: nil, limit: Number(0))
        #expect(grid.count == 0)
    }

    @Test func libs() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("a"): ["id": Ref("a"), "lib": Marker.val],
                Ref("b"): ["id": Ref("b"), "lib": Marker.val, "foo": "bar"],
                Ref("c"): ["id": Ref("c")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Test no filter
        var grid = try await server.libs(filter: nil, limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])

        // Test filter
        grid = try await server.libs(filter: "foo", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == ["b"])

        // Test bad filter
        grid = try await server.libs(filter: "none", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == [])

        // Test limit
        grid = try await server.libs(filter: nil, limit: Number(0))
        #expect(grid.count == 0)
    }

    @Test func ops() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("a"): ["id": Ref("a"), "def": Marker.val, "op": Marker.val],
                Ref("b"): ["id": Ref("b"), "def": Marker.val, "op": Marker.val, "foo": "bar"],
                Ref("c"): ["id": Ref("c")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Test no filter
        var grid = try await server.ops(filter: nil, limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])

        // Test filter
        grid = try await server.ops(filter: "foo", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == ["b"])

        // Test bad filter
        grid = try await server.ops(filter: "none", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == [])

        // Test limit
        grid = try await server.ops(filter: nil, limit: Number(0))
        #expect(grid.count == 0)
    }

    @Test func filetypes() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("a"): ["id": Ref("a"), "def": Marker.val, "filetype": Marker.val],
                Ref("b"): ["id": Ref("b"), "def": Marker.val, "filetype": Marker.val, "foo": "bar"],
                Ref("c"): ["id": Ref("c")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Test no filter
        var grid = try await server.filetypes(filter: nil, limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])

        // Test filter
        grid = try await server.filetypes(filter: "foo", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == ["b"])

        // Test bad filter
        grid = try await server.filetypes(filter: "none", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val } == [])

        // Test limit
        grid = try await server.filetypes(filter: nil, limit: Number(0))
        #expect(grid.count == 0)
    }

    @Test func readIds() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("a"): ["id": Ref("a"), "def": Marker.val, "filetype": Marker.val],
                Ref("b"): ["id": Ref("b"), "def": Marker.val, "filetype": Marker.val, "foo": "bar"],
                Ref("c"): ["id": Ref("c")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        let grid = try await server.read(ids: [Ref("a"), Ref("b")])
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])
    }

    @Test func readFilter() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("ahu"): ["id": Ref("ahu"), "equip": Marker.val, "ahu": Marker.val],
                Ref("supply-air-temp"): ["id": Ref("supply-air-temp"), "equipRef": Ref("ahu"), "point": Marker.val, "supply": Marker.val, "air": Marker.val, "temp": Marker.val, "sensor": Marker.val],
                Ref("vav"): ["id": Ref("vav"), "equip": Marker.val, "vav": Marker.val],
                Ref("discharge-air-temp"): ["id": Ref("supply-air-temp"), "equipRef": Ref("vav"), "point": Marker.val, "discharge": Marker.val, "air": Marker.val, "temp": Marker.val, "sensor": Marker.val],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Test normal
        var grid = try await server.read(filter: "equip", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["ahu", "vav"])

        // Test limit
        grid = try await server.read(filter: "equip", limit: Number(1))
        #expect(grid.count == 1)

        // Test and
        grid = try await server.read(filter: "equip and ahu", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["ahu"])

        // Test or
        grid = try await server.read(filter: "ahu or vav", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["ahu", "vav"])

        // Test path
        grid = try await server.read(filter: "point and equipRef->ahu", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["supply-air-temp"])

        // Test ref equality
        grid = try await server.read(filter: "equipRef == @ahu", limit: nil)
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["supply-air-temp"])
    }

    @Test func nav() async throws {
        let server = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("site"): ["id": Ref("site"), "site": Marker.val],
                Ref("equip"): ["id": Ref("equip"), "equip": Marker.val, "siteRef": Ref("site")],
                Ref("point"): ["id": Ref("point"), "point": Marker.val, "equipRef": Ref("equip"), "siteRef": Ref("site")],
            ]),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        var grid = try await server.nav(navId: nil)
        #expect(grid.compactMap { ($0["navId"] as? Ref)?.val }.sorted() == ["site"])

        grid = try await server.nav(navId: Ref("site"))
        #expect(grid.compactMap { ($0["navId"] as? Ref)?.val }.sorted() == ["equip"])

        grid = try await server.nav(navId: Ref("equip"))
        #expect(grid.compactMap { ($0["navId"] as? Ref)?.val }.sorted() == ["point"])
    }

    @Test func hisRead() async throws {
        // Test absolute time ranges

        let absoluteServer = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("point"): ["id": Ref("point")],
            ]),
            historyStore: InMemoryHistoryStore([
                Ref("point"): [
                    HisItem(ts: DateTime("2025-05-09T12:00:00-07:00"), val: Number(1)),
                    HisItem(ts: DateTime("2025-05-10T00:00:00-07:00"), val: Number(2)),
                    HisItem(ts: DateTime("2025-05-10T12:00:00-07:00"), val: Number(3)),
                    HisItem(ts: DateTime("2025-05-11T00:00:00-07:00"), val: Number(4)),
                ],
            ]),
            watchStore: InMemoryWatchStore()
        )

        // After
        var grid = try await absoluteServer.hisRead(id: Ref("point"), range: .after(DateTime("2025-05-09T17:00:00-07:00")))
        #expect(
            try grid.rows == [
                ["ts": DateTime("2025-05-10T00:00:00-07:00"), "val": Number(2)],
                ["ts": DateTime("2025-05-10T12:00:00-07:00"), "val": Number(3)],
                ["ts": DateTime("2025-05-11T00:00:00-07:00"), "val": Number(4)],
            ]
        )

        // Date
        grid = try await absoluteServer.hisRead(id: Ref("point"), range: .date(Date("2025-05-10")))
        #expect(
            try grid.rows == [
                ["ts": DateTime("2025-05-10T00:00:00-07:00"), "val": Number(2)],
                ["ts": DateTime("2025-05-10T12:00:00-07:00"), "val": Number(3)],
            ]
        )

        // Date Range
        grid = try await absoluteServer.hisRead(id: Ref("point"), range: .dateRange(from: Date("2025-05-10"), to: Date("2025-05-11")))
        #expect(
            try grid.rows == [
                ["ts": DateTime("2025-05-10T00:00:00-07:00"), "val": Number(2)],
                ["ts": DateTime("2025-05-10T12:00:00-07:00"), "val": Number(3)],
                ["ts": DateTime("2025-05-11T00:00:00-07:00"), "val": Number(4)],
            ]
        )

        // DateTime Range
        grid = try await absoluteServer.hisRead(id: Ref("point"), range: .dateTimeRange(from: DateTime("2025-05-10T00:00:00-07:00"), to: DateTime("2025-05-11T00:00:00-07:00")))
        #expect(
            try grid.rows == [
                ["ts": DateTime("2025-05-10T00:00:00-07:00"), "val": Number(2)],
                ["ts": DateTime("2025-05-10T12:00:00-07:00"), "val": Number(3)],
            ]
        )

        // Test relative time ranges

        let now = Date.now
        let yesterday = now.addingTimeInterval(-60 * 60 * 24)
        let dayBeforeYesterday = now.addingTimeInterval(-60 * 60 * 24 * 2)
        let tomorrow = now.addingTimeInterval(60 * 60 * 24)

        let relativeServer = try HaystackServer(
            recordStore: InMemoryRecordStore([
                Ref("point"): ["id": Ref("point")],
            ]),
            historyStore: InMemoryHistoryStore([
                Ref("point"): [
                    HisItem(ts: DateTime(date: dayBeforeYesterday), val: Number(1)),
                    HisItem(ts: DateTime(date: yesterday), val: Number(2)),
                    HisItem(ts: DateTime(date: now), val: Number(3)),
                    HisItem(ts: DateTime(date: tomorrow), val: Number(4)),
                ],
            ]),
            watchStore: InMemoryWatchStore()
        )

        grid = try await relativeServer.hisRead(id: Ref("point"), range: .today)
        #expect(
            grid.rows == [
                ["ts": DateTime(date: now), "val": Number(3)],
            ]
        )

        grid = try await relativeServer.hisRead(id: Ref("point"), range: .yesterday)
        #expect(
            grid.rows == [
                ["ts": DateTime(date: yesterday), "val": Number(2)],
            ]
        )
    }

    @Test func pointWrite() async throws {
        // TODO: Implement
    }

    @Test func pointWriteStatus() async throws {
        // TODO: Implement
    }

    // Test all watch methods together to avoid state complexities
    @Test func watch() async throws {
        let idA = try Ref("a")
        let idB = try Ref("b")
        let idC = try Ref("c")
        let recA: Dict = ["id": idA, "def": Marker.val]
        let recB: Dict = ["id": idB, "def": Marker.val, "foo": "bar"]
        let recC: Dict = ["id": idC]
        let recordStore = InMemoryRecordStore([
            idA: recA,
            idB: recB,
            idC: recC,
        ])
        let server = HaystackServer(
            recordStore: recordStore,
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore()
        )

        // Create the watch and validate A and B are returned
        var grid = try await server.watchSubCreate(watchDis: "ab", lease: nil, ids: [idA, idB])
        let watchId = try #require(grid.meta["watchId"] as? String)
        #expect(grid.meta == ["watchId": watchId, "lease": null])
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["a", "b"])

        // Change B to increment "mod"
        var newB = recB
        newB["new"] = Marker.val
        _ = try await recordStore.commitAll(diffs: [
            .init(id: idB, old: recB, new: newB),
        ])

        // Check that subsequent poll picks up B
        grid = try await server.watchPoll(watchId: watchId, refresh: false)
        #expect(grid.meta == ["watchId": watchId])
        #expect(grid.count == 1)
        #expect(grid.first?["id"] as? Ref == idB)
        #expect(grid.first?["new"] != nil)

        // Add C to the watch and validate C is returned
        grid = try await server.watchSubAdd(watchId: watchId, lease: nil, ids: [idC])
        #expect(grid.meta == ["watchId": watchId, "lease": null])
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["c"])

        // Change C to increment "mod"
        var newC = recC
        newC["new"] = Marker.val
        _ = try await recordStore.commitAll(diffs: [
            .init(id: idC, old: recC, new: newC),
        ])

        // Validate poll picks up C
        grid = try await server.watchPoll(watchId: watchId, refresh: false)
        #expect(grid.meta == ["watchId": watchId])
        #expect(grid.count == 1)
        #expect(grid.first?["id"] as? Ref == idC)
        #expect(grid.first?["new"] != nil)

        // Remove A from watch
        grid = try await server.watchUnsubRemove(watchId: watchId, ids: [Ref("a")])
        #expect(grid.isEmpty)

        // Change A to increment "mod"
        var newA = recA
        newA["new"] = Marker.val
        _ = try await recordStore.commitAll(diffs: [
            .init(id: idA, old: recA, new: newA),
        ])

        // Validate poll does not pick up A
        grid = try await server.watchPoll(watchId: watchId, refresh: false)
        #expect(grid.meta == ["watchId": watchId])
        #expect(grid.count == 0)

        // Test that poll with refresh gives B and C
        grid = try await server.watchPoll(watchId: watchId, refresh: true)
        #expect(grid.meta == ["watchId": watchId])
        #expect(grid.compactMap { ($0["id"] as? Ref)?.val }.sorted() == ["b", "c"])
    }

    @Test func invokeAction() async throws {
        let server = HaystackServer(
            recordStore: InMemoryRecordStore(),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore(),
            onInvokeAction: { id, action, args in
                let gb = GridBuilder()
                try gb.addRow(["id": id, "action": action, "args": Dict(args)])
                return gb.toGrid()
            }
        )
        let grid = try await server.invokeAction(id: Ref("1"), action: "a", args: ["foo": "bar"])
        #expect(try grid[0]["id"] as? Ref == Ref("1"))
        #expect(grid[0]["action"] as? String == "a")
        #expect(grid[0]["args"] as? Dict == Dict(["foo": "bar"]))
    }

    @Test func eval() async throws {
        let server = HaystackServer(
            recordStore: InMemoryRecordStore(),
            historyStore: InMemoryHistoryStore(),
            watchStore: InMemoryWatchStore(),
            onEval: { _ in
                let gb = GridBuilder()
                try gb.addRow(["foo": "bar"])
                return gb.toGrid()
            }
        )
        let grid = try await server.eval(expression: "anything")
        #expect(grid == [["foo": "bar"]])
    }
}

/// This is a super inefficient record store based on an in-memory list of Diffs
///
/// Any change automatically updates the `mod` DateTime tag on the record
actor InMemoryRecordStore: RecordStore {
    var recs: [Haystack.Ref: Haystack.Dict] = [:]

    init() {}

    init(_ dicts: [Haystack.Ref: Haystack.Dict]) {
        recs = [:]
        for (k, v) in dicts {
            var dictWithMod = v
            dictWithMod["mod"] = DateTime(date: .now)
            recs[k] = dictWithMod
        }
    }

    func read(ids: [Haystack.Ref]) async throws -> [Haystack.Dict] {
        return try ids.map { id in
            guard let rec = recs[id] else {
                throw ServerError.idNotFound(id)
            }
            return rec
        }
    }

    func read(filter: String, limit: Haystack.Number?) async throws -> [Haystack.Dict] {
        let filter = try FilterFactory.make(filter)
        var dicts = [Dict]()
        for rec in recs.values {
            if let limit = limit, dicts.count >= Int(limit.val) {
                break
            }
            if try filter.include(
                dict: rec,
                pather: { ref in
                    try? self.recs[Ref(ref)]
                }
            ) {
                dicts.append(rec)
            }
        }
        return dicts
    }

    func commitAll(diffs: [RecordDiff]) async throws -> [RecordDiff] {
        var updatedDiffs: [RecordDiff] = []
        for diff in diffs {
            var diffWithMod = diff.new
            diffWithMod["mod"] = DateTime(date: .now)
            if let oldRec = recs[diff.id] {
                recs[diff.id] = diffWithMod
                updatedDiffs.append(RecordDiff(id: diff.id, old: oldRec, new: diffWithMod))
            } else {
                recs[diff.id] = diffWithMod
                updatedDiffs.append(RecordDiff(id: diff.id, old: nil, new: diffWithMod))
            }
        }
        return updatedDiffs
    }
}

/// This is a super inefficient history store based on an in-memory list of histories
actor InMemoryHistoryStore: HistoryStore {
    /// Maps Refs to histories. These histories are not assumed to be ordered in time (for simplicity).
    var histories: [Ref: [HisItem]]

    init() {
        histories = [:]
    }

    init(_ histories: [Ref: [HisItem]] = [:]) {
        self.histories = histories
    }

    func hisRead(id: Ref, range: HisReadRange) async throws -> [Dict] {
        let start = range.start()
        let end = range.end()
        let history = histories[id] ?? []
        return history.filter { item in
            var inRange = true
            if let start = start, item.ts.date < start {
                inRange = false
            }
            if let end = end, end <= item.ts.date {
                inRange = false
            }
            return inRange
        }.sorted {
            $0.ts < $1.ts
        }.map {
            $0.toDict()
        }
    }

    func hisWrite(id: Ref, items: [HisItem]) async throws {
        var history = histories[id] ?? []
        history.append(contentsOf: items)
        histories[id] = history
    }
}

/// This is a super inefficient history store based on an in-memory list of histories
actor InMemoryWatchStore: WatchStore {
    /// Maps watch IDs to a list of Refs. This is used to track which records are being watched.
    var watches: [String: Watch] = [:]

    init() {
        watches = [:]
    }

    init(_ watches: [String: Watch] = [:]) {
        self.watches = watches
    }

    func read(watchId: String) async throws -> WatchResponse {
        guard let watch = watches[watchId] else {
            throw ServerError.watchNotFound(watchId)
        }
        return WatchResponse(ids: watch.ids, lease: watch.lease, lastReported: watch.lastReported)
    }

    func create(ids: [Haystack.Ref], lease: Haystack.Number?) async throws -> String {
        let watchId = UUID().uuidString
        watches[watchId] = Watch(id: watchId, ids: ids, lease: lease)
        return watchId
    }

    func addIds(watchId: String, ids: [Haystack.Ref]) async throws {
        guard var watch = watches[watchId] else {
            throw ServerError.watchNotFound(watchId)
        }
        watch.ids.append(contentsOf: ids)
        watches[watchId] = watch
    }

    func removeIds(watchId: String, ids: [Haystack.Ref]) async throws {
        guard var watch = watches[watchId] else {
            throw ServerError.watchNotFound(watchId)
        }
        watch.ids.removeAll { id in
            ids.contains(id)
        }
        watches[watchId] = watch
    }

    func updateLastReported(watchId: String) async throws {
        guard var watch = watches[watchId] else {
            throw ServerError.watchNotFound(watchId)
        }
        watch.lastReported = .now
        watches[watchId] = watch
    }

    func delete(watchId: String) async throws {
        watches[watchId] = nil
    }

    struct Watch: Hashable {
        let id: String
        var ids: [Haystack.Ref]
        let lease: Haystack.Number
        var lastReported: Foundation.Date?

        init(id: String, ids: [Haystack.Ref], lease: Haystack.Number?) {
            self.id = id
            self.ids = ids
            self.lease = lease ?? Number(1, unit: "hr")
            lastReported = nil
        }
    }
}
