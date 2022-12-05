import CryptoKit
import Haystack
import Foundation

@available(macOS 13.0, *)
public class HaystackClient {
    private let userAgentHeaderValue = "swift-haystack-client"
    
    public let baseUrl: URL
    private let username: String
    private let password: String
    private let format: DataFormat
    private let session: URLSession
    
    /// Set when `login` is called.
    private var authToken: String? = nil
    
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
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
    
    public func about() async throws -> Grid {
        return try await post(path: "about")
    }
    
    public func close() async throws {
        try await post(path: "close")
    }
    
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
    
    public func read(ids: [Ref]) async throws -> Grid {
        let builder = GridBuilder()
        try builder.addCol(name: "id")
        for id in ids {
            try builder.addRow([id])
        }
        return try await post(path: "read", grid: builder.toGrid())
    }
    
    public func readAll(filter: String, limit: Number? = nil) async throws -> Grid {
        var args: [String: any Val] = ["filter": filter]
        if let limit = limit {
            args["limit"] = limit
        }
        return try await post(path: "read", args: args)
    }
    
    public func nav(navId: Ref) async throws -> Grid {
        return try await post(path: "nav", args: ["navId": navId])
    }
    
    public func hisRead(id: Ref, range: HisReadRange) async throws -> Grid {
        return try await post(path: "hisRead", args: ["id": id, "range": range.toRequestString()])
    }
    
    
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

public enum DataFormat: String {
    case json
    case zinc
    
    // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
    var acceptHeaderValue: String {
        switch self {
        case .json: return "application/json"
        case .zinc: return "text/zinc"
        }
    }
    
    var contentTypeHeaderValue: String {
        switch self {
        case .json: return "application/json"
        case .zinc: return "text/zinc; charset=utf-8"
        }
    }
}

enum HaystackClientError: Error {
    case authHelloNoWwwAuthenticateHeader
    case authHelloHandshakeTokenNotPresent
    case authHelloHashFunctionNotPresent
    case authHashFunctionNotRecognized(String)
    case authMechanismNotRecognized(String)
    case authMechanismNotImplemented(AuthMechanism)
    case notLoggedIn
    case baseUrlCannotBeFile
    case responseIsNotZinc
    case requestFailed(httpCode: Int, message: String?)
}

enum AuthMechanism: String {
    case SCRAM
}

@available(macOS 10.15, *)
enum AuthHash: String {
    case SHA512 = "SHA-512"
    case SHA256 = "SHA-256"
    
    var hash: any HashFunction.Type {
        switch self {
        case .SHA256:
            return CryptoKit.SHA256.self
        case .SHA512:
            return CryptoKit.SHA512.self
        }
    }
}

enum HTTPHeader {
    static let accept = "Accept"
    static let authenticationInfo = "Authentication-Info"
    static let authorization = "Authorization"
    static let contentType = "Content-Type"
    static let userAgent = "User-Agent"
    static let wwwAuthenticate = "Www-Authenticate"
}

public enum HisReadRange {
    case today
    case yesterday
    case date(Haystack.Date)
    case dateRange(from: Haystack.Date, to: Haystack.Date)
    case dateTimeRange(from: DateTime, to: DateTime)
    case after(DateTime)
    
    func toRequestString() -> String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case let .date(date): return "\(date.toZinc())"
        case let .dateRange(fromDate, toDate): return "\(fromDate.toZinc()),\(toDate.toZinc())"
        case let .dateTimeRange(fromDateTime, toDateTime): return "\(fromDateTime.toZinc()),\(toDateTime.toZinc())"
        case let .after(dateTime): return "\(dateTime.toZinc())"
        }
    }
}
