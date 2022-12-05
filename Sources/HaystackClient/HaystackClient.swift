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
    
    public func login() async throws {
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
        return try await request(path: "about", method: .POST)
    }
    
    public func ops() async throws -> Grid {
        return try await request(path: "ops", method: .POST)
    }
    
    private func request(path: String, method: HttpMethod, args: [String: any Val] = [:]) async throws -> Grid {
        var url = baseUrl.appending(path: path)
        // Adjust url based on GET args
        if method == .GET && !args.isEmpty {
            var queryItems = [URLQueryItem]()
            for (argName, argValue) in args {
                queryItems.append(.init(name: argName, value: argValue.toZinc()))
            }
            url = url.appending(queryItems: queryItems)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Adjust body based on POST args
        if method == .POST {
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
            let data: Data
            switch format {
            case .json:
                data = try jsonEncoder.encode(grid)
            case .zinc:
                data = grid.toZinc().data(using: .utf8)! // Unwrap is safe b/c zinc is always UTF8 compatible
            }
            request.addValue(format.contentTypeHeaderValue, forHTTPHeaderField: HTTPHeader.contentType)
            request.httpBody = data
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
        do {
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
        } catch {
            throw error
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
