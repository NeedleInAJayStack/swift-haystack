import Crypto
import Haystack
import Foundation

@available(macOS 13.0, *)
/// A Haystack API client. Once created, call the `open` method to connect.
///
/// ```swift
/// let client = Client(
///     baseUrl: "http://localhost:8080/api",
///     username: "user",
///     password: "abc123"
/// )
/// await try client.open()
/// let about = await try client.about()
/// await try client.close()
/// ```
public class Client {
    let baseUrl: URL
    let username: String
    let password: String
    let format: DataFormat
    let session: URLSession
    
    /// Set when `open` is called.
    private var authToken: String? = nil
    
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    /// Create a client instance.This may be reused across multiple logins if needed.
    /// - Parameters:
    ///   - baseUrl: The URL of the Haystack API server
    ///   - username: The username to authenticate with
    ///   - password: The password to authenticate with
    ///   - format: The transfer data format. Defaults to `zinc` to reduce data transfer.
    public init(
        baseUrl: URL,
        username: String,
        password: String,
        format: DataFormat = .zinc
    ) throws {
        guard !baseUrl.isFileURL else {
            throw HaystackClientError.baseUrlCannotBeFile
        }
        self.baseUrl = baseUrl
        self.username = username
        self.password = password
        self.format = format
        
        // Disable all cookies, otherwise haystack thinks we're a browser client
        // and asks for an Attest-Key header
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpCookieAcceptPolicy = .never
        sessionConfig.httpShouldSetCookies = false
        sessionConfig.httpCookieStorage = nil
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    /// Authenticate the client and store the authentication token
    public func open() async throws {
        let url = baseUrl.appending(path: "about")
        
        // Hello
        let helloRequestAuth = AuthMessage(scheme: "hello", attributes: ["username": username.encodeBase64UrlSafe()])
        var helloRequest = URLRequest(url: url)
        helloRequest.addValue(helloRequestAuth.description, forHTTPHeaderField: HTTPHeader.authorization)
        let (_, helloResponse) = try await session.data(for: helloRequest)
        guard let helloHeaderString = (helloResponse as! HTTPURLResponse).value(forHTTPHeaderField: HTTPHeader.wwwAuthenticate) else {
            throw HaystackClientError.authHelloNoWwwAuthenticateHeader
        }
        let helloResponseAuth = try AuthMessage.from(helloHeaderString)
        guard let authMechanism = AuthMechanism(rawValue: helloResponseAuth.scheme.uppercased()) else {
            throw HaystackClientError.authMechanismNotRecognized(helloResponseAuth.scheme)
        }
        guard let hashString = helloResponseAuth.attributes["hash"] else {
            throw HaystackClientError.authHelloHashFunctionNotPresent
        }
        guard let hash = AuthHash(rawValue: hashString) else {
            throw HaystackClientError.authHashFunctionNotRecognized(hashString)
        }
        guard let handshakeToken = helloResponseAuth.attributes["handshakeToken"] else {
            throw HaystackClientError.authHelloHashFunctionNotPresent
        }
        
        let authenticator: any Authenticator
        switch authMechanism {
        case .SCRAM:
            switch hash {
            case .SHA256:
                authenticator = ScramAuthenticator<SHA256>(
                    url: baseUrl,
                    username: username,
                    password: password,
                    handshakeToken: handshakeToken,
                    session: session
                )
            case .SHA512:
                authenticator = ScramAuthenticator<SHA512>(
                    url: baseUrl,
                    username: username,
                    password: password,
                    handshakeToken: handshakeToken,
                    session: session
                )
            }
        // TODO: Implement PLAINTEXT auth scheme
        }
        self.authToken = try await authenticator.getAuthToken()
    }
    
    /// Closes the current authentication session.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#close
    public func close() async throws {
        try await post(path: "close")
        self.authToken = nil
    }
    
    /// Queries basic information about the server
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#about
    public func about() async throws -> Grid {
        return try await post(path: "about")
    }
    
    /// Queries def dicts from the current namespace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#defs
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    public func defs(filter: String? = nil, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = [:]
        if let filter = filter {
            args["filter"] = filter
        }
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "defs", args: args)
    }
    
    /// Queries lib defs from current namspace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#libs
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    public func libs(filter: String? = nil, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = [:]
        if let filter = filter {
            args["filter"] = filter
        }
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "libs", args: args)
    }
    
    /// Queries op defs from current namspace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#ops
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    public func ops(filter: String? = nil, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = [:]
        if let filter = filter {
            args["filter"] = filter
        }
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "ops", args: args)
    }
    
    /// Queries filetype defs from current namspace
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#filetypes
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of defs to return in response
    /// - Returns: A grid with the dict representation of each def
    public func filetypes(filter: String? = nil, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = [:]
        if let filter = filter {
            args["filter"] = filter
        }
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "filetypes", args: args)
    }
    
    /// Read a set of entity records by their unique identifier
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#read
    ///
    /// - Parameter ids: Ref identifiers
    /// - Returns: A grid with a row for each entity read
    public func read(ids: [Ref]) async throws -> Grid {
        let builder = GridBuilder()
        try builder.addCol(name: "id")
        for id in ids {
            try builder.addRow([id])
        }
        return try await post(path: "read", grid: builder.toGrid())
    }
    
    /// Read a set of entity records using a filter
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#read
    ///
    /// - Parameters:
    ///   - filter: A string filter
    ///   - limit: The maximum number of entities to return in response
    /// - Returns: A grid with a row for each entity read
    public func read(filter: String, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = ["filter": filter]
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "read", args: args)
    }
    
    /// Navigate a project for learning and discovery
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#nav
    ///
    /// - Parameter navId: The ID of the entity to navigate from. If null, the navigation root is used.
    /// - Returns: A grid of navigation children for the navId specified by the request
    public func nav(navId: Ref?) async throws -> Grid {
        if let navId = navId {
            return try await post(path: "nav", args: ["navId": navId])
        } else {
            return try await post(path: "nav", args: [:])
        }
    }
    
    /// Reads time-series data from historized point
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#hisRead
    ///
    /// - Parameters:
    ///   - id: Identifier of historized point
    ///   - range: A date-time range
    /// - Returns: A grid whose rows represent timetamp/value pairs with a DateTime ts column and a val column for each scalar value
    public func hisRead(id: Ref, range: HisReadRange) async throws -> Grid {
        return try await post(path: "hisRead", args: ["id": id, "range": range.toRequestString()])
    }
    
    /// Posts new time-series data to a historized point
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#hisWrite
    ///
    /// - Parameters:
    ///   - id: The identifier of the point to write to
    ///   - items: New timestamp/value samples to write
    /// - Returns: An empty grid
    public func hisWrite(id: Ref, items: [HisItem]) async throws -> Grid {
        let builder = GridBuilder()
        builder.setMeta(["id": id])
        try builder.addCol(name: "ts")
        try builder.addCol(name: "val")
        for item in items {
            try builder.addRow([item.ts, item.val])
        }
        return try await post(path: "hisWrite", grid: builder.toGrid())
    }
    
    /// Write to a given level of a writable point's priority array
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
    ///
    /// - Parameters:
    ///   - id: Identifier of writable point
    ///   - level: Number from 1-17 for level to write
    ///   - val: Value to write or null to auto the level
    ///   - who: Username/application name performing the write, otherwise authenticated user display name is used
    ///   - duration: Number with duration unit if setting level 8
    /// - Returns: An empty grid
    public func pointWrite(
        id: Ref,
        level: Number,
        val: any Val,
        who: String? = nil,
        duration: Number? = nil
    ) async throws -> Grid {
        // level must be int between 1 & 17, check duration is duration unit and is present when level is 8
        guard
            level.isInt,
            1 <= level.val,
            level.val <= 17
        else {
            throw HaystackClientError.pointWriteLevelIsNotIntBetween1And17
        }
        
        var args: [String: any Val] = [
            "id": id,
            "level": level,
            "val": val
        ]
        if let who = who {
            args["who"] = who
        }
        if level.val == 8, let duration = duration {
            // TODO: Check that duration has time units
            args["duration"] = duration
        }
        
        return try await post(path: "pointWrite", args: args)
    }
    
    /// Read the current status of a writable point's priority array
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#pointWrite
    ///
    /// - Parameter id: Identifier of writable point
    /// - Returns: A grid with current priority array state
    public func pointWriteStatus(id: Ref) async throws -> Grid {
        return try await post(path: "pointWrite", args: ["id": id])
    }
    
    /// Used to create new watches.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
    ///
    /// - Parameters:
    ///   - watchDis: Debug/display string
    ///   - lease: Number with duration unit for desired lease period
    ///   - ids: The identifiers of the entities to subscribe to
    /// - Returns: A grid where rows correspond to the current entity state of the requested identifiers.  Grid metadata contains
    /// `watchId` and `lease`.
    public func watchSubCreate(
        watchDis: String,
        lease: Number? = nil,
        ids: [Ref]
    ) async throws -> Grid {
        var gridMeta: [String: any Val] = ["watchDis": watchDis]
        if let lease = lease {
            gridMeta["lease"] = lease
        }
        
        let builder = GridBuilder()
        builder.setMeta(gridMeta)
        try builder.addCol(name: "id")
        for id in ids {
            try builder.addRow([id])
        }
        
        return try await post(path: "watchSub", grid: builder.toGrid())
    }
    
    /// Used to add entities to an existing watch.
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchSub
    ///
    /// - Parameters:
    ///   - watchId: Debug/display string
    ///   - lease: Number with duration unit for desired lease period
    ///   - ids: The identifiers of the entities to subscribe to
    /// - Returns: A grid where rows correspond to the current entity state of the requested identifiers.  Grid metadata contains
    /// `watchId` and `lease`.
    public func watchSubAdd(
        watchId: String,
        lease: Number? = nil,
        ids: [Ref]
    ) async throws -> Grid {
        var gridMeta: [String: any Val] = ["watchId": watchId]
        if let lease = lease {
            gridMeta["lease"] = lease
        }
        
        let builder = GridBuilder()
        builder.setMeta(gridMeta)
        try builder.addCol(name: "id")
        for id in ids {
            try builder.addRow([id])
        }
        
        return try await post(path: "watchSub", grid: builder.toGrid())
    }
    
    /// Used to close a watch entirely or remove entities from a watch
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchUnsub
    ///
    /// - Parameters:
    ///   - watchId: Watch identifier
    ///   - ids: Ref values for each entity to unsubscribe. If empty the entire watch is closed.
    /// - Returns: An empty grid
    public func watchUnsub(
        watchId: String,
        ids: [Ref]
    ) async throws -> Grid {
        var gridMeta: [String: any Val] = ["watchId": watchId]
        if ids.isEmpty {
            gridMeta["close"] = marker
        }
        
        let builder = GridBuilder()
        builder.setMeta(gridMeta)
        try builder.addCol(name: "id")
        for id in ids {
            try builder.addRow([id])
        }
        
        return try await post(path: "watchUnsub", grid: builder.toGrid())
    }
    
    /// Used to poll a watch for changes to the subscribed entity records
    ///
    /// https://project-haystack.org/doc/docHaystack/Ops#watchPoll
    ///
    /// - Parameters:
    ///   - watchId: Watch identifier
    ///   - refresh: Whether a full refresh should occur
    /// - Returns: A grid where each row correspondes to a watched entity
    public func watchPoll(
        watchId: String,
        refresh: Bool = false
    ) async throws -> Grid {
        var gridMeta: [String: any Val] = ["watchId": watchId]
        if refresh {
            gridMeta["refresh"] = marker
        }
        
        let builder = GridBuilder()
        builder.setMeta(gridMeta)
        
        return try await post(path: "watchPoll", grid: builder.toGrid())
    }
    
    /// https://project-haystack.org/doc/docHaystack/Ops#invokeAction
    /// - Parameters:
    ///   - id: Identifier of target rec
    ///   - action: The name of the action func
    ///   - args: The arguments to the action
    /// - Returns: A grid of undefined shape
    public func invokeAction(
        id: Ref,
        action: String,
        args: [String: any Val]
    ) async throws -> Grid {
        let gridMeta: [String: any Val] = [
            "id": id,
            "action": action
        ]
        let builder = GridBuilder()
        builder.setMeta(gridMeta)
        var row = [any Val]()
        for (argName, argVal) in args {
            try builder.addCol(name: argName)
            row.append(argVal)
        }
        try builder.addRow(row)
        
        return try await post(path: "invokeAction", grid: builder.toGrid())
    }
    
    /// Evaluate an Axon expression
    ///
    /// https://haxall.io/doc/lib-hx/op~eval
    ///
    /// - Parameter expression: A string Axon expression
    /// - Returns: A grid of undefined shape
    public func eval(expression: String) async throws -> Grid {
        return try await post(path: "eval", args: ["expr": expression])
    }
    
    @discardableResult
    private func post(path: String, args: [String: any Val] = [:]) async throws -> Grid {
        let grid: Grid
        if args.isEmpty {
            // Create empty grid
            grid = GridBuilder().toGrid()
        } else {
            let builder = GridBuilder()
            var row = [any Val]()
            for (argName, argValue) in args {
                try builder.addCol(name: argName)
                row.append(argValue)
            }
            try builder.addRow(row)
            grid = builder.toGrid()
        }
        
        return try await post(path: path, grid: grid)
    }
    
    @discardableResult
    private func post(path: String, grid: Grid) async throws -> Grid {
        let url = baseUrl.appending(path: path)
        return try await execute(url: url, method: .POST, grid: grid)
    }
    
    @discardableResult
    private func get(path: String, args: [String: any Val] = [:]) async throws -> Grid {
        var url = baseUrl.appending(path: path)
        // Adjust url based on GET args
        if !args.isEmpty {
            var queryItems = [URLQueryItem]()
            for (argName, argValue) in args {
                queryItems.append(.init(name: argName, value: argValue.toZinc()))
            }
            url = url.appending(queryItems: queryItems)
        }
        return try await execute(url: url, method: .GET)
    }
    
    private func execute(url: URL, method: HttpMethod, grid: Grid? = nil) async throws -> Grid {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if method == .POST, let grid = grid {
            let requestData: Data
            switch format {
            case .json:
                requestData = try jsonEncoder.encode(grid)
            case .zinc:
                requestData = grid.toZinc().data(using: .utf8)! // Unwrap is safe b/c zinc is always UTF8 compatible
            }
            request.addValue(format.contentTypeHeaderValue, forHTTPHeaderField: HTTPHeader.contentType)
            request.httpBody = requestData
        }
        
        // Set auth token header
        guard let authToken = authToken else {
            throw HaystackClientError.notLoggedIn
        }
        request.addValue(
            AuthMessage(scheme: "Bearer", attributes: ["authToken": authToken]).description,
            forHTTPHeaderField: HTTPHeader.authorization
        )
        // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
        request.addValue(format.acceptHeaderValue, forHTTPHeaderField: HTTPHeader.accept)
        request.addValue(userAgentHeaderValue, forHTTPHeaderField: HTTPHeader.userAgent)
        let (data, responseGen) = try await session.data(for: request)
        let response = (responseGen as! HTTPURLResponse)
        guard response.statusCode == 200 else {
            throw HaystackClientError.requestFailed(
                httpCode: response.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }
        guard
            let contentType = response.value(forHTTPHeaderField: HTTPHeader.contentType),
            contentType.hasPrefix(format.acceptHeaderValue)
        else {
            throw HaystackClientError.responseIsNotZinc
        }
        switch format {
        case .json:
            return try jsonDecoder.decode(Grid.self, from: data)
        case .zinc:
            return try ZincReader(data).readGrid()
        }
    }
    
    private enum HttpMethod: String {
        case GET
        case POST
    }
}

private let userAgentHeaderValue = "swift-haystack-client"

enum HaystackClientError: Error {
    case authHelloNoWwwAuthenticateHeader
    case authHelloHandshakeTokenNotPresent
    case authHelloHashFunctionNotPresent
    case authHashFunctionNotRecognized(String)
    case authMechanismNotRecognized(String)
    case authMechanismNotImplemented(AuthMechanism)
    case baseUrlCannotBeFile
    case notLoggedIn
    case pointWriteLevelIsNotIntBetween1And17
    case responseIsNotZinc
    case requestFailed(httpCode: Int, message: String?)
}

enum AuthMechanism: String {
    case SCRAM
}

enum HTTPHeader {
    static let accept = "Accept"
    static let authenticationInfo = "Authentication-Info"
    static let authorization = "Authorization"
    static let contentType = "Content-Type"
    static let userAgent = "User-Agent"
    static let wwwAuthenticate = "Www-Authenticate"
}
