import Haystack
import Vapor

/// A route collection that exposes Haystack API endpoints.
public struct HaystackRouteCollection: RouteCollection {

    /// This instance defines all Haystack API processing that is done server-side.
    let delegate: any API

    public init(delegate: any API) {
        self.delegate = delegate
    }

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
            let dict = request.queryDict()
            let filter: String?
            let limit: Number?
            do {
                filter = try dict.get("filter", as: String.self)
                limit = try dict.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.defs(filter: filter, limit: limit)
            )
        }

        /// Queries def dicts from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.post("defs") { request in
            let grid = try request.decodeGrid()
            let filter: String?
            let limit: Number?
            do {
                filter = try grid.first?.get("filter", as: String.self)
                limit = try grid.first?.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.defs(filter: filter, limit: limit)
            )
        }

        /// Queries lib defs from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("libs") { request in
            let dict = request.queryDict()
            let filter: String?
            let limit: Number?
            do {
                filter = try dict.get("filter", as: String.self)
                limit = try dict.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.libs(filter: filter, limit: limit)
            )
        }

        /// Queries lib defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#libs
        routes.post("libs") { request in
            let grid = try request.decodeGrid()
            let filter: String?
            let limit: Number?
            do {
                filter = try grid.first?.get("filter", as: String.self)
                limit = try grid.first?.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.libs(filter: filter, limit: limit)
            )
        }

        /// Queries lib defs from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("ops") { request in
            let dict = request.queryDict()
            let filter: String?
            let limit: Number?
            do {
                filter = try dict.get("filter", as: String.self)
                limit = try dict.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.libs(filter: filter, limit: limit)
            )
        }

        /// Queries op defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#ops
        routes.post("ops") { request in
            let grid = try request.decodeGrid()
            let filter: String?
            let limit: Number?
            do {
                filter = try grid.first?.get("filter", as: String.self)
                limit = try grid.first?.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.ops(filter: filter, limit: limit)
            )
        }

        /// Queries lib defs from the current namespace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#defs
        routes.get("filetypes") { request in
            let dict = request.queryDict()
            let filter: String?
            let limit: Number?
            do {
                filter = try dict.get("filter", as: String.self)
                limit = try dict.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.filetypes(filter: filter, limit: limit)
            )
        }

        /// Queries filetype defs from current namspace
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#filetypes
        routes.post("filetypes") { request in
            let grid = try request.decodeGrid()
            let filter: String?
            let limit: Number?
            do {
                filter = try grid.first?.get("filter", as: String.self)
                limit = try grid.first?.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.filetypes(filter: filter, limit: limit)
            )
        }

        /// Read a set of entity records by their unique identifier
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#read
        routes.get("read") { request in
            let dict = request.queryDict()
            let ids: [Ref]?
            let filter: String?
            let limit: Number?
            do {
                let id = try dict.get("id", as: List.self)
                ids = try id?.map { element in
                    guard let id = element as? Ref else {
                        throw Abort(.badRequest, reason: "`id` elements must be Ref")
                    }
                    return id
                }
                filter = try dict.get("filter", as: String.self)
                limit = try dict.get("limit", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            if let ids = ids {
                return try await request.respond(with: delegate.read(ids: ids))
            } else if let filter = filter {
                return try await request.respond(
                    with: delegate.read(filter: filter, limit: limit)
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
            var ids: [Ref]? = nil
            var filter: String? = nil
            var limit: Number? = nil
            do {
                if grid.cols.contains(where: { $0.name == "id" }) {
                    ids = try grid.map { try $0.trap("id", as: Ref.self) }
                } else {
                    guard let firstRow = grid.first else {
                        throw Abort(.badRequest, reason: "Request grid must not be empty")
                    }
                    filter = try firstRow.trap("filter", as: String.self)
                    limit = try firstRow.get("limit", as: Number.self)
                }
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            if let ids = ids {
                return try await request.respond(with: delegate.read(ids: ids))
            } else if let filter = filter {
                return try await request.respond(
                    with: delegate.read(filter: filter, limit: limit)
                )
            } else {
                throw Abort(.badRequest, reason: "Read request must have either 'id' or 'filter'")
            }
        }

        /// Navigate a project for learning and discovery
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#nav
        routes.get("nav") { request in
            let dict = request.queryDict()
            let navId: Ref?
            do {
                navId = try dict.get("navId", as: Ref.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.nav(navId: navId)
            )
        }

        /// Navigate a project for learning and discovery
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#nav
        routes.post("nav") { request in
            let grid = try request.decodeGrid()
            let navId: Ref?
            do {
                navId = try grid.first?.get("navId", as: Ref.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.nav(navId: navId)
            )
        }

        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.get("hisRead") { request in
            let dict = request.queryDict()
            let id: Ref
            let range: HisReadRange
            do {
                id = try dict.trap("id", as: Ref.self)
                range = try HisReadRange.fromZinc(dict.trap("range", as: String.self))
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.hisRead(
                    id: id,
                    range: range
                )
            )
        }

        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisRead") { request in
            let grid = try request.decodeGrid()
            guard let row = grid.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            let id: Ref
            let range: HisReadRange
            do {
                id = try row.trap("id", as: Ref.self)
                range = try HisReadRange.fromZinc(row.trap("range", as: String.self))
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(
                with: delegate.hisRead(
                    id: id,
                    range: range
                )
            )
        }

        /// Reads time-series data from historized point
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
        routes.post("hisWrite") { request in
            let grid = try request.decodeGrid()
            let id: Ref
            let items: [HisItem]
            do {
                id = try grid.meta.trap("id", as: Ref.self)
                items = try grid.map { row in
                    let ts = try row.trap("ts", as: DateTime.self)
                    let val = try row.trap("val")
                    return HisItem(ts: ts, val: val)
                }
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
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
            guard let args = grid.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }

            // Check for pointWrite status by checking for a level
            let id: Ref
            let level: Number?
            do {
                id = try args.trap("id", as: Ref.self)
                level = try args.get("level", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }
            guard let level = level else {
                return try await request.respond(
                    with: delegate.pointWriteStatus(id: id)
                )
            }

            // Otherwise, do a pointWrite
            let val: any Val
            let who: String?
            let duration: Number?
            do {
                val = try args.trap("val")
                who = try args.get("who", as: String.self)
                duration = try args.get("duration", as: Number.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }
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

            let ids: [Ref]
            let lease: Number?
            let watchDis: String?
            let watchId: String?
            do {
                ids = try grid.map { row in
                    try row.trap("id", as: Ref.self)
                }
                lease = try grid.meta.get("lease", as: Number.self)
                watchDis = try grid.meta.get("watchDis", as: String.self)
                watchId = try grid.meta.get("watchId", as: String.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            if let watchDis = watchDis {
                return try await request.respond(
                    with: delegate.watchSubCreate(
                        watchDis: watchDis,
                        lease: lease,
                        ids: ids
                    )
                )
            }

            if let watchId = watchId {
                return try await request.respond(
                    with: delegate.watchSubAdd(
                        watchId: watchId,
                        lease: lease,
                        ids: ids
                    )
                )
            }

            throw Abort(.badRequest, reason: "Meta must include either `watchDis` or `watchId`")
        }

        /// Used to close a watch entirely or remove entities from a watch
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchUnsub
        routes.post("watchUnsub") { request in
            let grid = try request.decodeGrid()

            let watchId: String
            do {
                watchId = try grid.meta.trap("watchId", as: String.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            if grid.meta.has("close") {
                return try await request.respond(
                    with: delegate.watchUnsubDelete(
                        watchId: watchId
                    )
                )
            } else {
                let ids: [Ref]
                do {
                    ids = try grid.map { row in
                        try row.trap("id", as: Ref.self)
                    }
                } catch {
                    throw Abort(.badRequest, reason: error.localizedDescription)
                }

                return try await request.respond(
                    with: delegate.watchUnsubRemove(
                        watchId: watchId,
                        ids: ids
                    )
                )
            }
        }

        /// Used to poll a watch for changes to the subscribed entity records
        ///
        /// https://project-haystack.org/doc/docHaystack/Ops#watchPoll
        routes.post("watchPoll") { request in
            let grid = try request.decodeGrid()
            let watchId: String
            let refresh: Bool
            do {
                watchId = try grid.meta.trap("watchId", as: String.self)
                refresh = try grid.meta.get("refresh", as: Bool.self) ?? false
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

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
            let id: Ref
            let action: String
            do {
                id = try grid.meta.trap("id", as: Ref.self)
                action = try grid.meta.trap("action", as: String.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }
            var args = [String: any Val]()
            if let row = grid.first {
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
            guard let args = grid.first else {
                throw Abort(.badRequest, reason: "Request grid must not be empty")
            }
            let expr: String
            do {
                expr = try args.trap("expr", as: String.self)
            } catch {
                throw Abort(.badRequest, reason: error.localizedDescription)
            }

            return try await request.respond(with: delegate.eval(expression: expr))
        }
    }
}
