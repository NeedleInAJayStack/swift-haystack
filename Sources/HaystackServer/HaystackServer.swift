import Foundation
import Haystack

public class HaystackServer: API {
    let recordStore: RecordStore
    let historyStore: HistoryStore
    let watchStore: WatchStore
    
    let onInvokeAction: (Haystack.Ref, String, [String : any Haystack.Val]) async throws -> Haystack.Grid
    let onEval: (String) async throws -> Haystack.Grid

    public init(
        recordStore: RecordStore,
        historyStore: HistoryStore,
        watchStore: WatchStore,
        onInvokeAction: @escaping (Haystack.Ref, String, [String : any Haystack.Val]) async throws -> Haystack.Grid = { _, _, _ in
            GridBuilder().toGrid()
        },
        onEval: @escaping (String) async throws -> Haystack.Grid = { _ in
            GridBuilder().toGrid()
        }
    ) {
        self.recordStore = recordStore
        self.historyStore = historyStore
        self.watchStore = watchStore
        self.onInvokeAction = onInvokeAction
        self.onEval = onEval
    }

    public func close() async throws {
        return
    }

    public func about() async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        try gb.addRow([
            "haystackVersion": "4.0",
            "tz": "New_York",
            "serverName": "Test Server",
            "serverTime": DateTime(date: Foundation.Date()),
            "serverBootTime": DateTime(date: Foundation.Date() - ProcessInfo.processInfo.systemUptime),
            "productName": "swift-haystack",
            "productUri": Uri("https://github.com/NeedleInAJayStack/swift-haystack"),
            "productVersion": "0.0.0", // TODO: Version
            "vendorName": "NeedleInAJayStack",
            "vendorUri": Uri("https://github.com/NeedleInAJayStack"),
        ])
        return gb.toGrid()
    }

    public func defs(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var queryFilter = "def"
        if let filter = filter {
            queryFilter += " and (\(filter))"
        }
        let dicts = try await recordStore.read(filter: queryFilter, limit: limit)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func libs(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var queryFilter = "lib"
        if let filter = filter {
            queryFilter += " and (\(filter))"
        }
        let dicts = try await recordStore.read(filter: queryFilter, limit: limit)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func ops(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var queryFilter = "def and op"
        if let filter = filter {
            queryFilter += " and (\(filter))"
        }
        let dicts = try await recordStore.read(filter: queryFilter, limit: limit)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func filetypes(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var queryFilter = "def and filetype"
        if let filter = filter {
            queryFilter += " and (\(filter))"
        }
        let dicts = try await recordStore.read(filter: queryFilter, limit: limit)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func read(ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        let dicts = try await recordStore.read(ids: ids)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func read(filter: String, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        let dicts = try await recordStore.read(filter: filter, limit: limit)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func nav(navId: Haystack.Ref?) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }

    public func hisRead(id: Haystack.Ref, range: Haystack.HisReadRange) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        try gb.addCol(name: "ts")
        try gb.addCol(name: "val")
        let dicts = try await historyStore.hisRead(id: id, range: range)
        try gb.addRows(dicts)
        return gb.toGrid()
    }

    public func hisWrite(id: Haystack.Ref, items: [Haystack.HisItem]) async throws -> Haystack.Grid {
        try await historyStore.hisWrite(id: id, items: items)
        return GridBuilder().toGrid()
    }

    public func pointWrite(id: Haystack.Ref, level: Haystack.Number, val: any Haystack.Val, who: String?, duration: Haystack.Number?) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }

    public func pointWriteStatus(id: Haystack.Ref) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }

    public func watchSubCreate(watchDis: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        let watchId = try await watchStore.create(ids: ids, lease: lease)
        let builder = GridBuilder().setMeta([
            "watchId": watchId,
            "lease": lease ?? Haystack.Null.val
        ])
        let watchRecs = try await recordStore.read(ids: ids)
        try builder.addRows(watchRecs)
        try await watchStore.updateLastReported(watchId: watchId)
        return builder.toGrid()
    }

    public func watchSubAdd(watchId: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        try await watchStore.addIds(watchId: watchId, ids: ids)
        let builder = GridBuilder().setMeta([
            "watchId": watchId,
            "lease": lease ?? Haystack.Null.val
        ])
        let watchRecs = try await recordStore.read(ids: ids)
        try builder.addRows(watchRecs)
        try await watchStore.updateLastReported(watchId: watchId)
        return builder.toGrid()
    }

    public func watchUnsubRemove(watchId: String, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        try await watchStore.removeIds(watchId: watchId, ids: ids)
        return GridBuilder().toGrid()
    }
    
    public func watchUnsubDelete(watchId: String) async throws -> Haystack.Grid {
        try await watchStore.delete(watchId: watchId)
        return GridBuilder().toGrid()
    }

    public func watchPoll(watchId: String, refresh: Bool) async throws -> Haystack.Grid {
        let watch = try await watchStore.read(watchId: watchId)
        let builder = GridBuilder().setMeta([
            "watchId": watchId
        ])
        var watchRecs = [Dict]()
        if refresh {
            watchRecs = try await recordStore.read(ids: watch.ids)
        } else {
            watchRecs = try await recordStore.read(ids: watch.ids).filter { rec in
                return try rec.trap("mod", as: DateTime.self).date > watch.lastReported ?? .distantPast
            }
        }

        try builder.addRows(watchRecs)
        try await watchStore.updateLastReported(watchId: watchId)
        return builder.toGrid()
    }

    public func invokeAction(id: Haystack.Ref, action: String, args: [String : any Haystack.Val]) async throws -> Haystack.Grid {
        return try await self.onInvokeAction(id, action, args)
    }

    public func eval(expression: String) async throws -> Haystack.Grid {
        return try await self.onEval(expression)
    }
}

public enum ServerError: Error {
    case idNotFound(Haystack.Ref)
    case watchNotFound(String)
}
