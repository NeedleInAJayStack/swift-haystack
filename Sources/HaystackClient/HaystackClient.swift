import CryptoKit
import Haystack
import Foundation

@available(macOS 13.0, *)
public class HaystackClient {
    public let baseUrl: URL
    private let username: String
    private let password: String
    private let format: DataFormat
    
    /// Set when `login` is called.
    private var authToken: String? = nil
    
    private let jsonDecoder = JSONDecoder()
    
    public init(baseUrl: URL, username: String, password: String, format: DataFormat = .zinc) throws {
        guard !baseUrl.isFileURL else {
            throw HaystackClientError.baseUrlCannotBeFile
        }
        self.baseUrl = baseUrl
        self.username = username
        self.password = password
        self.format = format
    }
    
    public func login() async throws {
        let url = baseUrl.appending(path: "about")
        
        // Hello
        let helloRequestAuth = AuthMessage(scheme: "hello", attributes: ["username": username.encodeBase64UrlSafe()])
        var helloRequest = URLRequest(url: url)
        helloRequest.addValue(helloRequestAuth.description, forHTTPHeaderField: "Authorization")
        let (_, helloResponse) = try await URLSession.shared.data(for: helloRequest)
        guard let helloHeaderString = (helloResponse as! HTTPURLResponse).value(forHTTPHeaderField: "Www-Authenticate") else {
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
                    handshakeToken: handshakeToken
                )
            case .SHA512:
                authenticator = ScramAuthenticator<SHA512>(
                    url: baseUrl,
                    username: username,
                    password: password,
                    handshakeToken: handshakeToken
                )
            }
        // TODO: Implement PLAINTEXT auth scheme
        }
        self.authToken = try await authenticator.getAuthToken()
    }
    
    public func about() async throws -> Grid {
        return try await requestGrid(path: "about", method: .GET)
    }
    
    private func requestGrid(path: String, method: HttpMethod) async throws -> Grid {
        let url = baseUrl.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        guard let authToken = authToken else {
            throw HaystackClientError.notLoggedIn
        }
        request.addValue("BEARER \(authToken)", forHTTPHeaderField: "Authentication")
        // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
        request.addValue(format.acceptHeaderValue, forHTTPHeaderField: "Accept")
        let (data, responseGen) = try await URLSession.shared.data(for: request)
        let response = (responseGen as! HTTPURLResponse)
        guard
            let contentType = response.value(forHTTPHeaderField: "Content-Type"),
            contentType.hasPrefix(format.acceptHeaderValue)
        else {
            throw HaystackClientError.responseIsNotZinc
        }
        switch format {
        case .json: return try jsonDecoder.decode(Grid.self, from: data)
        case .zinc: return try ZincReader(data).readGrid()
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
