import Foundation
import Haystack

/// A HaystackServer is a server that implements the Haystack API.
/// It translates API calls into operations on the underlying data stores.
public final class HaystackServer: API, Sendable {
    let recordStore: RecordStore
    let historyStore: HistoryStore
    let watchStore: WatchStore
    let navPath: [String]

    let onInvokeAction: @Sendable (Haystack.Ref, String, [String: any Haystack.Val]) async throws -> Haystack.Grid
    let onEval: @Sendable (String) async throws -> Haystack.Grid

    public init(
        recordStore: RecordStore,
        historyStore: HistoryStore,
        watchStore: WatchStore,
        navPath: [String] = ["site", "equip", "point"],
        onInvokeAction: @escaping @Sendable (Haystack.Ref, String, [String: any Haystack.Val]) async throws -> Haystack.Grid = { _, _, _ in
            GridBuilder().toGrid()
        },
        onEval: @escaping @Sendable (String) async throws -> Haystack.Grid = { _ in
            GridBuilder().toGrid()
        }
    ) {
        self.recordStore = recordStore
        self.historyStore = historyStore
        self.watchStore = watchStore
        self.navPath = navPath
        self.onInvokeAction = onInvokeAction
        self.onEval = onEval
    }

    public func close() async throws {}

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

    public func nav(navId parentId: Haystack.Ref?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        try gb.addCol(name: "navId")
        guard navPath.count > 0 else {
            return gb.toGrid()
        }
        guard let parentId = parentId else {
            // If no input, just return the first level of navigation
            for result in try await recordStore.read(filter: "\(navPath[0])", limit: nil) {
                var navResult = result
                navResult["navId"] = result["id"]
                try gb.addRow(navResult)
            }
            return gb.toGrid()
        }
        guard let parentDict = try await recordStore.read(ids: [parentId]).first else {
            throw ServerError.idNotFound(parentId)
        }
        // Find the first component of the navPath that matches a tag on the input dict
        var parentNavPathIndex: Int? = nil
        for index in 0 ..< navPath.count {
            let component = navPath[index]
            if parentDict.has(component) {
                parentNavPathIndex = index
            }
        }
        guard let parentNavPathIndex = parentNavPathIndex else {
            throw ServerError.navPathComponentNotFound(navPath)
        }
        guard parentNavPathIndex < navPath.count - 1 else {
            // Parent is a navPath leaf. No further navigation is possible, so return nothing.
            return gb.toGrid()
        }
        let parentNavComponent = navPath[parentNavPathIndex]
        let childNavComponent = navPath[parentNavPathIndex + 1]
        // Read children using child component and inferring parent ref tag
        let children = try await recordStore.read(
            filter: "\(childNavComponent) and \(parentNavComponent)Ref == \(parentId.toZinc())",
            limit: nil
        )
        for child in children {
            var navChild = child
            navChild["navId"] = child["id"]
            try gb.addRow(navChild)
        }
        return gb.toGrid()
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

    public func pointWrite(id _: Haystack.Ref, level _: Haystack.Number, val _: any Haystack.Val, who _: String?, duration _: Haystack.Number?) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }

    public func pointWriteStatus(id _: Haystack.Ref) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }

    public func watchSubCreate(watchDis _: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        let watchId = try await watchStore.create(ids: ids, lease: lease)
        let builder = GridBuilder().setMeta([
            "watchId": watchId,
            "lease": lease ?? Haystack.Null.val,
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
            "lease": lease ?? Haystack.Null.val,
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
            "watchId": watchId,
        ])
        var watchRecs = [Dict]()
        if refresh {
            watchRecs = try await recordStore.read(ids: watch.ids)
        } else {
            watchRecs = try await recordStore.read(ids: watch.ids).filter { rec in
                try rec.trap("mod", as: DateTime.self).date > watch.lastReported ?? .distantPast
            }
        }

        try builder.addRows(watchRecs)
        try await watchStore.updateLastReported(watchId: watchId)
        return builder.toGrid()
    }

    public func invokeAction(id: Haystack.Ref, action: String, args: [String: any Haystack.Val]) async throws -> Haystack.Grid {
        return try await onInvokeAction(id, action, args)
    }

    public func eval(expression: String) async throws -> Haystack.Grid {
        return try await onEval(expression)
    }
}

public enum ServerError: Error {
    case idNotFound(Haystack.Ref)
    case navPathComponentNotFound([String])
    case watchNotFound(String)
}
