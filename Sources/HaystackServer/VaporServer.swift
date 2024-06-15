import Haystack
import Vapor

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
        routes.get("about") { request in
            return try await request.respond(with: delegate.about())
        }
        
        /// Queries basic information about the server
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#about
        routes.post("about") { request in
            return try await request.respond(with: delegate.about())
        }
        
        /// Queries def dicts from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("defs") { request in
            let args = try request.query.decode(DefsArgs.self)
            return try await request.respond(
                with: delegate.defs(filter: args.filter, limit: args.limit)
            )
        }
        
        /// Queries def dicts from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.post("defs") { request in
            let grid = try request.decodeGrid()
            let args = try DefsArgs(
                filter: grid.rows.first?.get("filter", as: String.self),
                limit: grid.rows.first?.get("limit", as: Number.self)
            )
            return try await request.respond(
                with: delegate.defs(filter: args.filter, limit: args.limit)
            )
        }
        
        struct DefsArgs: Content {
            var filter: String?
            var limit: Number?
        }
        
        /// Queries lib defs from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("libs") { request in
            let args = try request.query.decode(LibsArgs.self)
            return try await request.respond(
                with: delegate.libs(filter: args.filter, limit: args.limit)
            )
        }
        
        /// Queries lib defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#libs
        routes.post("libs") { request in
            let grid = try request.decodeGrid()
            let args = try LibsArgs(
                filter: grid.rows.first?.get("filter", as: String.self),
                limit: grid.rows.first?.get("limit", as: Number.self)
            )
            return try await request.respond(
                with: delegate.libs(filter: args.filter, limit: args.limit)
            )
        }
        
        struct LibsArgs: Content {
            var filter: String?
            var limit: Number?
        }
        
        /// Queries lib defs from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("ops") { request in
            let args = try request.query.decode(OpsArgs.self)
            return try await request.respond(
                with: delegate.libs(filter: args.filter, limit: args.limit)
            )
        }
        
        /// Queries op defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#ops
        routes.post("ops") { request in
            let grid = try request.decodeGrid()
            let args = try OpsArgs(
                filter: grid.rows.first?.get("filter", as: String.self),
                limit: grid.rows.first?.get("limit", as: Number.self)
            )
            return try await request.respond(
                with: delegate.ops(filter: args.filter, limit: args.limit)
            )
        }
        
        struct OpsArgs: Content {
            var filter: String?
            var limit: Number?
        }
        
        /// Queries filetype defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#filetypes
        routes.post("filetypes") { request in
            let grid = try request.decodeGrid()
            let args = try FiletypesArgs(
                filter: grid.rows.first?.get("filter", as: String.self),
                limit: grid.rows.first?.get("limit", as: Number.self)
            )
            return try await request.respond(
                with: delegate.filetypes(filter: args.filter, limit: args.limit)
            )
        }
        
        struct FiletypesArgs: Content {
            var filter: String?
            var limit: Number?
        }
        
        /// Read a set of entity records by their unique identifier
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#read
        routes.get("read") { request in
            let args = try request.query.decode(ReadArgs.self)
            
            if let id = args.id {
                return try await request.respond(with: delegate.read(ids: id))
            } else if let filter = args.filter {
                return try await request.respond(
                    with: delegate.read(filter: filter, limit: args.limit)
                )
            } else {
                throw Abort(.badRequest, reason: "Read request must have either 'id' or 'filter'")
            }
        }
        
        /// Read a set of entity records by their unique identifier
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#read
        routes.post("read") { request in
            let grid = try request.decodeGrid()
            let args: ReadArgs
            guard let firstRow = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            if grid.cols.contains(where: { $0.name == "id" }) {
                args = try ReadArgs(id: grid.rows.map { try $0.trap("id", as: Ref.self) })
            } else {
                args = try ReadArgs(
                    filter: firstRow.trap("filter", as: String.self),
                    limit: firstRow.get("limit", as: Number.self)
                )
            }
            
            if let id = args.id {
                return try await request.respond(with: delegate.read(ids: id))
            } else if let filter = args.filter {
                return try await request.respond(
                    with: delegate.read(filter: filter, limit: args.limit)
                )
            } else {
                throw Abort(.badRequest, reason: "Read request must have either 'id' or 'filter'")
            }
        }
        
        struct ReadArgs: Content {
            var id: [Ref]?
            var filter: String?
            var limit: Number?
        }
        
        /// Navigate a project for learning and discovery
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#nav
        routes.get("nav") { request in
            let args = try request.query.decode(NavArgs.self)
            return try await request.respond(
                with: delegate.nav(navId: args.navId)
            )
        }
        
        /// Navigate a project for learning and discovery
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#nav
        routes.post("nav") { request in
            let grid = try request.decodeGrid()
            let args = NavArgs(
                navId: try grid.rows.first?.get("navId", as: Ref.self)
            )
            return try await request.respond(
                with: delegate.nav(navId: args.navId)
            )
        }
        
        struct NavArgs: Content {
            var navId: Ref?
        }
        
        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.get("hisRead") { request in
            let args = try request.content.decode(HisReadArgs.self)
            return try await request.respond(
                with: delegate.hisRead(
                    id: args.id,
                    range: HisReadRange.fromRequestString(str: args.range)
                )
            )
        }
        
        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisRead") { request in
            let grid = try request.decodeGrid()
            guard let row = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            let args = try HisReadArgs(
                id: row.trap("id", as: Ref.self),
                range: row.trap("range", as: String.self)
            )
            return try await request.respond(
                with: delegate.hisRead(
                    id: args.id,
                    range: HisReadRange.fromRequestString(str: args.range)
                )
            )
        }
        
        struct HisReadArgs: Content {
            var id: Ref
            var range: String
        }
        
        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisWrite") { request in
            let grid = try request.decodeGrid()
            let id = try grid.meta.trap("id", as: Ref.self)
            let items = try grid.rows.map { row in
                let ts = try row.trap("ts", as: DateTime.self)
                let val = try row.trap("val")
                return HisItem(ts: ts, val: val)
            }
            return try await request.respond(
                with: delegate.hisWrite(id: id, items: items)
            )
        }
        
        /// Write to a given level of a writable point's priority array
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
        routes.post("pointWrite") { request in
            let grid = try request.decodeGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            let id = try args.trap("id", as: Ref.self)
            guard let level = try args.get("level", as: Number.self) else {
                return try await request.respond(
                    with: delegate.pointWriteStatus(id: id)
                )
            }
            
            let val = try args.trap("val")
            let who = try args.get("who", as: String.self)
            let duration = try args.get("who", as: Number.self)
            return try await request.respond(
                with: delegate.pointWrite(
                    id: id,
                    level: level,
                    val: val,
                    who: who,
                    duration: duration
                )
            )
        }
        
        /// Used to create new watches.
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
        routes.post("watchSub") { request in
            let grid = try request.decodeGrid()
            
            let ids = try grid.rows.map { row in
                try row.trap("id", as: Ref.self)
            }
            let lease = try grid.meta.get("lease", as: Number.self)
            
            if let watchDis = try grid.meta.get("watchDis", as: String.self) {
                return try await request.respond(
                    with: delegate.watchSubCreate(
                        watchDis: watchDis,
                        lease: lease,
                        ids: ids
                    )
                )
            }
            
            if let watchId = try grid.meta.get("watchId", as: String.self) {
                return try await request.respond(
                    with: delegate.watchSubAdd(
                        watchId: watchId,
                        lease: lease,
                        ids: ids
                    )
                )
            }
            
            throw Abort(.badRequest, reason: "Meta must include `watchDis` or `watchId`")
        }
        
        /// Used to close a watch entirely or remove entities from a watch
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchUnsub
        routes.post("watchUnsub") { request in
            let grid = try request.decodeGrid()
            
            let watchId = try grid.meta.trap("watchId", as: String.self)
            let ids = try grid.rows.map { row in
                try row.trap("id", as: Ref.self)
            }
            
            return try await request.respond(
                with: delegate.watchUnsub(
                    watchId: watchId,
                    ids: ids
                )
            )
        }
        
        /// Used to poll a watch for changes to the subscribed entity records
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchPoll
        routes.post("watchPoll") { request in
            let grid = try request.decodeGrid()
            
            let watchId = try grid.meta.trap("watchId", as: String.self)
            let refresh = try grid.meta.get("refresh", as: Bool.self) ?? false
            
            return try await request.respond(
                with: delegate.watchPoll(
                    watchId: watchId,
                    refresh: refresh
                )
            )
        }
        
        /// Used to invoke a user action on a target record
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#invokeAction
        routes.post("invokeAction") { request in
            let grid = try request.decodeGrid()
            
            let id = try grid.meta.trap("id", as: Ref.self)
            let action = try grid.meta.trap("action", as: String.self)
            var args = [String: any Val]()
            if let row = grid.rows.first {
                args = row.elements
            }
            
            return try await request.respond(
                with: delegate.invokeAction(
                    id: id,
                    action: action,
                    args: args
                )
            )
        }
        
        /// Evaluate an Axon expression
        ///
        /// https://haxall.io/doc/lib-hx/op~eval
        routes.post("eval") { request in
            let grid = try request.decodeGrid()
            guard let args = grid.rows.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            
            let expr = try args.trap("expr", as: String.self)
            return try await request.respond(with: delegate.eval(expression: expr))
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

extension HTTPMediaType {
    static let zinc = HTTPMediaType(type: "text", subType: "zinc", parameters: ["charset": "utf-8"])
}

extension Grid: Content {}

extension Request {
    /// Returns the grid parsed from the request body according to the `content-type` header
    func decodeGrid() throws -> Grid {
        let grid: Grid
        switch self.headers.contentType {
        case .zinc:
            guard let body = self.body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            return try ZincReader(body).readGrid()
        default:
            grid = try self.content.decode(Grid.self)
        }
        return grid
    }
    
    /// Responds with the grid, encoded according to the `accept` header. See https://project-haystack.org/doc/docHaystack/HttpApi#contentNegotiation
    func respond(with grid: Grid) async throws -> Response {
        let accept = self.headers.accept
        if accept.isEmpty || accept.mediaTypes.contains(.zinc) {
            return Response(body: .init(stringLiteral: grid.toZinc()))
        } else {
            return try await grid.encodeResponse(for: self)
        }
    }
}
