import Foundation
import Haystack

/// This is a super inefficient server based on an in-memory list of Diffs
public struct InMemoryServer: API {
    var recs: [Dict]
    var histories: [Ref: [HisItem]]
    
    public init(recs: [Dict], histories: [Ref: [HisItem]]) {
        self.recs = recs
        self.histories = histories
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
            "serverBootTime": DateTime(date: Foundation.Date()), // TODO: Boot time
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
        var dicts = recs.filter { $0.has("def") }
        // TODO: Add filter support
        if let limit = limit {
            dicts = Array(dicts[0 ..< min(Int(limit.val), dicts.count - 1)])
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func libs(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var dicts = recs.filter { $0.has("def") && $0.has("lib") }
        // TODO: Add filter support
        if let limit = limit {
            dicts = Array(dicts[0 ..< min(Int(limit.val), dicts.count - 1)])
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func ops(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var dicts = recs.filter { $0.has("def") && $0.has("op") }
        // TODO: Add filter support
        if let limit = limit {
            dicts = Array(dicts[0 ..< min(Int(limit.val), dicts.count - 1)])
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func filetypes(filter: String?, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var dicts = recs.filter { $0.has("def") && $0.has("filetype") }
        // TODO: Add filter support
        if let limit = limit {
            dicts = Array(dicts[0 ..< min(Int(limit.val), dicts.count - 1)])
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func read(ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        let dicts = try ids.map { id in
            let rec = try recs.first { rec in
                try rec.trap("id", as: Ref.self) == id
            }
            guard let rec = rec else {
                throw ServerError.idNotFound(id)
            }
            return rec
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func read(filter: String, limit: Haystack.Number?) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        var dicts = recs
        // TODO: Add filter support
        if let limit = limit {
            dicts = Array(dicts[0 ..< min(Int(limit.val), dicts.count - 1)])
        }
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func nav(navId: Haystack.Ref?) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func hisRead(id: Haystack.Ref, range: Haystack.HisReadRange) async throws -> Haystack.Grid {
        let gb = Haystack.GridBuilder()
        let start = range.start()
        let end = range.end()
        let history = histories[id] ?? []
        let dicts = history.filter { item in
            var inRange = true
            if let start = start, item.ts.date < start {
                inRange = false
            }
            if let end = end, end <= item.ts.date {
                inRange = false
            }
            return inRange
        }.map { $0.toDict() }
        
        try gb.addRows(dicts)
        return gb.toGrid()
    }
    
    public func hisWrite(id: Haystack.Ref, items: [Haystack.HisItem]) async throws -> Haystack.Grid {
        // TODO: Implement
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
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func watchSubAdd(watchId: String, lease: Haystack.Number?, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func watchUnsub(watchId: String, ids: [Haystack.Ref]) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func watchPoll(watchId: String, refresh: Bool) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func invokeAction(id: Haystack.Ref, action: String, args: [String : any Haystack.Val]) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
    
    public func eval(expression: String) async throws -> Haystack.Grid {
        // TODO: Implement
        return GridBuilder().toGrid()
    }
}

public enum ServerError: Error {
    case idNotFound(Haystack.Ref)
}
