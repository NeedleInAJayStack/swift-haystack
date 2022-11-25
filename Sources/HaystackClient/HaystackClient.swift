import CryptoKit
import Haystack
import Foundation

@available(macOS 13.0, *)
public class HaystackClient {
    public let baseUrl: URL
    private let username: String
    private let password: String
    
    /// Set when `login` is called.
    private var authToken: String? = nil
    
    public init(baseUrl: URL, username: String, password: String) throws {
        guard !baseUrl.isFileURL else {
            throw HaystackClientError.baseUrlCannotBeFile
        }
        self.baseUrl = baseUrl
        self.username = username
        self.password = password
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
        let aboutUrl = baseUrl.appending(path: "about")
        
        var request = URLRequest(url: aboutUrl)
        request.httpMethod = "GET"
        request.addValue("text/zinc", forHTTPHeaderField: "Accept")
        let (data, responseGen) = try await URLSession.shared.data(for: request)
        let response = (responseGen as! HTTPURLResponse)
        guard response.value(forHTTPHeaderField: "Content-Type") == "text/zinc" else {
            throw HaystackClientError.responseIsNotZinc
        }
        return try ZincReader(data).readGrid()
    }
}

enum HaystackClientError: Error {
    case authHelloNoWwwAuthenticateHeader
    case authHelloHandshakeTokenNotPresent
    case authHelloHashFunctionNotPresent
    case authHashFunctionNotRecognized(String)
    case authMechanismNotRecognized(String)
    case authMechanismNotImplemented(AuthMechanism)
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
