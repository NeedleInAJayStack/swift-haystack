import Haystack
import Vapor

// TODO: Add `get` support and `json` support.
public struct VaporServer: RouteCollection {
    
    /// This instance defines all Haystack API processing that is done server-side.
    let delegate: any API
    
    public func boot(routes: any Vapor.RoutesBuilder) throws {
        
        /// Closes the current authentication session.
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#close
        routes.post("close") { request in
            try await delegate.close()
            return ""
        }
        
        /// Queries basic information about the server
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#about
        routes.post("about") { request in
            return try await delegate.about().toZinc()
        }
        
        /// Queries def dicts from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.post("defs") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            var filter: String? = nil
            var limit: Number? = nil
            if let args = grid.rows.first {
                filter = try args.trap("filter", as: String.self)
                if let limitArg = try args.get("limit", as: Number.self) {
                    limit = limitArg
                }
            }
            return try await delegate.defs(filter: filter, limit: limit).toZinc()
        }
        
        /// Queries lib defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#libs
        routes.post("libs") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            var filter: String? = nil
            var limit: Number? = nil
            if let args = grid.rows.first {
                filter = try args.trap("filter", as: String.self)
                if let limitArg = try args.get("limit", as: Number.self) {
                    limit = limitArg
                }
            }
            return try await delegate.libs(filter: filter, limit: limit).toZinc()
        }
        
        /// Queries op defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#ops
        routes.post("ops") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            var filter: String? = nil
            var limit: Number? = nil
            if let args = grid.rows.first {
                filter = try args.trap("filter", as: String.self)
                if let limitArg = try args.get("limit", as: Number.self) {
                    limit = limitArg
                }
            }
            return try await delegate.ops(filter: filter, limit: limit).toZinc()
        }
        
        /// Queries filetype defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#filetypes
        routes.post("filetypes") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            var filter: String? = nil
            var limit: Number? = nil
            if let args = grid.rows.first {
                filter = try args.trap("filter", as: String.self)
                if let limitArg = try args.get("limit", as: Number.self) {
                    limit = limitArg
                }
            }
            return try await delegate.filetypes(filter: filter, limit: limit).toZinc()
        }
        
        /// Read a set of entity records by their unique identifier
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#read
        routes.post("read") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            if let id = try args.get("id", as: Ref.self) {
                return try await delegate.read(ids: [id]).toZinc()
            } else {
                let filter = try args.trap("filter", as: String.self)
                var limit: Number? = nil
                if let limitArg = try args.get("limit", as: Number.self) {
                    limit = limitArg
                }
                return try await delegate.read(filter: filter, limit: limit).toZinc()
            }
        }
        
        /// Navigate a project for learning and discovery
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#nav
        routes.post("nav") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            var navId: Ref? = nil
            if let args = grid.rows.first {
                navId = try args.trap("navId", as: Ref.self)
            }
            return try await delegate.nav(navId: navId).toZinc()
        }
        
        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisRead") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            let id = try args.trap("id", as: Ref.self)
            let rangeStr = try args.trap("range", as: String.self)
            let range = try HisReadRange.fromRequestString(str: rangeStr)
            
            return try await delegate.hisRead(id: id, range: range).toZinc()
        }
        
        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisWrite") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            let id = try grid.meta.trap("id", as: Ref.self)
            let items = try grid.rows.map { row in
                let ts = try row.trap("ts", as: DateTime.self)
                let val = try row.trap("val")
                return HisItem(ts: ts, val: val)
            }
            
            return try await delegate.hisWrite(id: id, items: items).toZinc()
        }
        
        /// Write to a given level of a writable point's priority array
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
        routes.post("pointWrite") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            let id = try args.trap("id", as: Ref.self)
            guard let level = try args.get("level", as: Number.self) else {
                return try await delegate.pointWriteStatus(id: id).toZinc()
            }
            
            let val = try args.trap("val")
            let who = try args.get("who", as: String.self)
            let duration = try args.get("who", as: Number.self)
            return try await delegate.pointWrite(
                id: id,
                level: level,
                val: val,
                who: who,
                duration: duration
            ).toZinc()
        }
        
        /// Used to create new watches.
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
        routes.post("watchSub") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            let ids = try grid.rows.map { row in
                try row.trap("id", as: Ref.self)
            }
            let lease = try grid.meta.get("lease", as: Number.self)
            
            if let watchDis = try grid.meta.get("watchDis", as: String.self) {
                return try await delegate.watchSubCreate(
                    watchDis: watchDis,
                    lease: lease,
                    ids: ids
                ).toZinc()
            }
            
            if let watchId = try grid.meta.get("watchId", as: String.self) {
                return try await delegate.watchSubAdd(
                    watchId: watchId,
                    lease: lease,
                    ids: ids
                ).toZinc()
            }
            
            throw Abort(.badRequest, reason: "Meta must include `watchDis` or `watchId`")
        }
        
        /// Used to close a watch entirely or remove entities from a watch
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchUnsub
        routes.post("watchUnsub") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            let watchId = try grid.meta.trap("watchId", as: String.self)
            let ids = try grid.rows.map { row in
                try row.trap("id", as: Ref.self)
            }
            
            return try await delegate.watchUnsub(
                watchId: watchId,
                ids: ids
            ).toZinc()
        }
        
        /// Used to poll a watch for changes to the subscribed entity records
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchPoll
        routes.post("watchPoll") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            let watchId = try grid.meta.trap("watchId", as: String.self)
            let refresh = try grid.meta.get("refresh", as: Bool.self) ?? false
            
            return try await delegate.watchPoll(
                watchId: watchId,
                refresh: refresh
            ).toZinc()
        }
        
        /// Used to invoke a user action on a target record
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#invokeAction
        routes.post("invokeAction") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            
            let id = try grid.meta.trap("id", as: Ref.self)
            let action = try grid.meta.trap("action", as: String.self)
            var args = [String: any Val]()
            if let row = grid.rows.first {
                args = row.elements
            }
            
            return try await delegate.invokeAction(
                id: id,
                action: action,
                args: args
            ).toZinc()
        }
        
        /// Evaluate an Axon expression
        ///
        /// https://haxall.io/doc/lib-hx/op~eval
        routes.post("eval") { request in
            guard let body = request.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            let grid = try ZincReader(body).readGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            let expr = try args.trap("expr", as: String.self)
            return try await delegate.eval(expression: expr).toZinc()
        }
    }
}

extension HisReadRange {
    static func fromRequestString(str: String) throws -> Self {
        if str == "today" {
            return .today
        }
        if str == "yesterday" {
            return .yesterday
        }
        if str.contains(",") {
            let split = str.split(separator: ",")
            let fromStr = String(split[0])
            let fromVal = try ZincReader(fromStr).readVal()
            let toStr = String(split[1])
            let toVal = try ZincReader(toStr).readVal()
            
            switch fromVal {
            case let fromDate as Haystack.Date:
                switch toVal {
                case let toDate as Haystack.Date:
                    return .dateRange(from: fromDate, to: toDate)
                default:
                    throw HisReadRangeError.fromAndToDontMatch(fromStr, toStr)
                }
            case let fromDateTime as DateTime:
                switch toVal {
                case let toDateTime as DateTime:
                    return .dateTimeRange(from: fromDateTime, to: toDateTime)
                default:
                    throw HisReadRangeError.fromAndToDontMatch(fromStr, toStr)
                }
            default:
                throw HisReadRangeError.formatNotRecognized(str)
            }
            
            
        }
        let val = try ZincReader(str).readVal()
        switch val {
        case let date as Haystack.Date:
            return .date(date)
        case let dateTime as DateTime:
            return .after(dateTime)
        default:
            throw HisReadRangeError.formatNotRecognized(str)
        }
    }
}

enum HisReadRangeError: Error {
    case fromAndToDontMatch(String, String)
    case formatNotRecognized(String)
}
