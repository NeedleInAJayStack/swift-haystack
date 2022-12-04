import CryptoKit
import Foundation

@available(macOS 13.0, *)
protocol Authenticator {
    func getAuthToken() async throws -> String
}

@available(macOS 13.0, *)
struct ScramAuthenticator<Hash: HashFunction>: Authenticator {
    let url: URL
    let username: String
    let password: String
    let handshakeToken: String
    let session: URLSession
    
    init(
        url: URL,
        username: String,
        password: String,
        handshakeToken: String
    ) {
        self.url = url
        self.username = username
        self.password = password
        self.handshakeToken = handshakeToken
        
        // It seems we need a separate session to avoid storing cookies? I guess?
        self.session = URLSession(configuration: .ephemeral)
    }
    
    func getAuthToken() async throws -> String {
        let aboutUrl = url.appending(path: "about")
        
        let scram = ScramClient(
            hash: Hash.self,
            username: username,
            password: password
        )
        
        // Authentication Exchange
        
        // Client Initiation
        let clientFirstMessage = scram.clientFirstMessage()
        var firstRequest = URLRequest(url: aboutUrl)
        firstRequest.addValue(
            AuthMessage(
                scheme: "scram",
                attributes: [
                    "handshakeToken": handshakeToken,
                    "data": clientFirstMessage.encodeBase64UrlSafe()
                ]
            ).description,
            forHTTPHeaderField: "Authorization"
        )
        let (_, firstResponseGen) = try await session.data(for: firstRequest)
        let firstResponse = (firstResponseGen as! HTTPURLResponse)
        
        // Server Initiation Response
        guard firstResponse.statusCode == 401 else {
            throw ScramAuthenticatorError.FirstResponseStatusIsNot401(firstResponse.statusCode)
        }
        guard let firstResponseHeaderString = firstResponse.value(forHTTPHeaderField: "Www-Authenticate") else {
            throw ScramAuthenticatorError.FirstResponseNoHeaderWwwAuthenticate
        }
        let firstResponseAuth = try AuthMessage.from(firstResponseHeaderString)
        guard AuthMechanism(rawValue: firstResponseAuth.scheme.uppercased()) == .SCRAM else {
            throw ScramAuthenticatorError.FirstResponseInconsistentMechanism
        }
        guard let handshakeToken2 = firstResponseAuth.attributes["handshakeToken"] else {
            throw ScramAuthenticatorError.FirstResponseNoAttributeHandshakeToken
        }
        guard let firstResponseData = firstResponseAuth.attributes["data"] else {
            throw ScramAuthenticatorError.FirstResponseNoAttributeData
        }
        guard let firstResponseHashString = firstResponseAuth.attributes["hash"] else {
            throw ScramAuthenticatorError.FirstResponseNoAttributeHash
        }
        guard let firstResponseHash = AuthHash(rawValue: firstResponseHashString) else {
            throw HaystackClientError.authHashFunctionNotRecognized(firstResponseHashString)
        }
        guard firstResponseHash.hash == Hash.self else {
            throw ScramAuthenticatorError.FirstResponseInconsistentHash
        }
        let serverFirstMessage = firstResponseData.decodeBase64UrlSafe()
        
        // Client Continuation
        let clientFinalMessage = try scram.clientFinalMessage(serverFirstMessage: serverFirstMessage)
        var finalRequest = URLRequest(url: aboutUrl)
        finalRequest.addValue(
            AuthMessage(
                scheme: "scram",
                attributes: [
                    "handshakeToken": handshakeToken2,
                    "data": clientFinalMessage.encodeBase64UrlSafe()
                ]
            ).description,
            forHTTPHeaderField: "Authorization"
        )
        let (_, finalResponseGen) = try await session.data(for: finalRequest)
        let finalResponse = (finalResponseGen as! HTTPURLResponse)
        
        // Final Server Message
        guard finalResponse.statusCode == 200 else {
            throw ScramAuthenticatorError.authFailedWithHttpCode(finalResponse.statusCode)
        }
        guard let finalResponseHeaderString = finalResponse.value(forHTTPHeaderField: "Authentication-Info") else {
            throw ScramAuthenticatorError.SecondResponseNoHeaderAuthenticationInfo
        }
        let finalResponseAttributes = extractNameValuePairs(from: finalResponseHeaderString)
        guard let authToken = finalResponseAttributes["authToken"] else {
            throw ScramAuthenticatorError.SecondResponseNoAttributeAuthToken
        }
        guard let finalResponseData = finalResponseAttributes["data"] else {
            throw ScramAuthenticatorError.SecondResponseNoAttributeData
        }
        guard let finalResponseHashString = finalResponseAttributes["hash"] else {
            throw ScramAuthenticatorError.SecondResponseNoAttributeHash
        }
        guard let finalResponseHash = AuthHash(rawValue: finalResponseHashString) else {
            throw HaystackClientError.authHashFunctionNotRecognized(finalResponseHashString)
        }
        guard finalResponseHash.hash == Hash.self else {
            throw ScramAuthenticatorError.SecondResponseInconsistentHash
        }
        let serverFinalMessage = finalResponseData.decodeBase64UrlSafe()
        try scram.validate(serverFinalMessage: serverFinalMessage)
        return authToken
    }
    
    
    enum ScramAuthenticatorError: Error {
        case FirstResponseInconsistentMechanism
        case FirstResponseNoAttributeData
        case FirstResponseNoAttributeHandshakeToken
        case FirstResponseNoAttributeHash
        case FirstResponseInconsistentHash
        case FirstResponseNoHeaderWwwAuthenticate
        case FirstResponseStatusIsNot401(Int)
        case SecondResponseNoAttributeAuthToken
        case SecondResponseNoAttributeData
        case SecondResponseNoAttributeHash
        case SecondResponseInconsistentHash
        case SecondResponseNoHeaderAuthenticationInfo
        case authFailedWithHttpCode(Int)
    }
}

struct AuthMessage: CustomStringConvertible {
    let scheme: String
    let attributes: [String: String]
    
    var description: String {
        // Unwrap is safe because attributes is immutable
        "\(scheme) \(attributes.keys.sorted().map { "\($0)=\(attributes[$0]!)" }.joined(separator: ", "))"
    }
    
    static func from(_ string: String) throws -> Self {
        // Example input: "SCRAM hash=SHA-256, handshakeToken=aabbcc"
        let scheme: String
        let attributes: [String: String]
        // If space exists then parse attributes as well.
        if let spaceIndex = string.firstIndex(of: " ") {
            scheme = String(string[..<spaceIndex]).trimmingCharacters(in: .whitespaces)
            let attributesString = String(string[spaceIndex...]).trimmingCharacters(in: .whitespaces)
            attributes = extractNameValuePairs(from: attributesString)
        } else {
            scheme = string
            attributes = [:]
        }
        return Self(scheme: scheme, attributes: attributes)
    }
}
