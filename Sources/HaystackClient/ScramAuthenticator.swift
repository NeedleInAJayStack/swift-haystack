import Crypto
import Foundation
import HaystackAPI

struct ScramAuthenticator<Hash: HashFunction>: Authenticator {
    let url: String
    let username: String
    let password: String
    let handshakeToken: String
    let fetcher: Fetcher
    
    init(
        url: String,
        username: String,
        password: String,
        handshakeToken: String,
        fetcher: Fetcher
    ) {
        var urlWithSlash = url
        if !urlWithSlash.hasSuffix("/") {
            urlWithSlash += "/"
        }
        self.url = urlWithSlash
        self.username = username
        self.password = password
        self.handshakeToken = handshakeToken
        self.fetcher = fetcher
    }
    
    func getAuthToken() async throws -> String {
        let aboutUrl = url + "about"
        
        let scram = ScramClient(
            hash: Hash.self,
            username: username,
            password: password
        )
        
        // Authentication Exchange
        
        // Client Initiation
        let clientFirstMessage = scram.clientFirstMessage()
        let firstRequest = HaystackRequest(
            url: aboutUrl,
            headerAuthorization: AuthMessage(
                    scheme: "scram",
                    attributes: [
                        "handshakeToken": handshakeToken,
                        "data": clientFirstMessage.encodeBase64UrlSafe()
                    ]
                ).description
        )
        let firstResponse = try await fetcher.fetch(firstRequest)
        
        // Server Initiation Response
        guard firstResponse.statusCode == 401 else {
            throw ScramAuthenticatorError.FirstResponseStatusIsNot401(firstResponse.statusCode)
        }
        guard let firstResponseHeaderString = firstResponse.headerWwwAuthenticate else {
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
        let finalRequest = HaystackRequest(
            url: aboutUrl,
            headerAuthorization: AuthMessage(
                    scheme: "scram",
                    attributes: [
                        "handshakeToken": handshakeToken2,
                        "data": clientFinalMessage.encodeBase64UrlSafe()
                    ]
                ).description
        )
        let finalResponse = try await fetcher.fetch(finalRequest)
        
        // Final Server Message
        guard finalResponse.statusCode == 200 else {
            throw ScramAuthenticatorError.authFailedWithHttpCode(finalResponse.statusCode)
        }
        guard let finalResponseHeaderString = finalResponse.headerAuthenticationInfo else {
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
