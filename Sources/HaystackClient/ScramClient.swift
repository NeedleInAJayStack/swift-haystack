import Crypto
import Foundation
import HaystackAPI

@available(macOS 10.15, *)
/// A Salted Challenge Response Authentication Mechanism (SCRAM) Client that is compatible with
/// [RFC 5802](https://www.rfc-editor.org/rfc/rfc5802)
class ScramClient<Hash: HashFunction> {
    private let clientKeyData = "Client Key".data(using: .utf8)!
    private let serverKeyData = "Server Key".data(using: .utf8)!
    
    private let username: String
    private let password: String
    private let clientNonce: String
    
    // Populated as messages are built up
    private var saltedPassword: Data? = nil
    private var authMessage: Data? = nil
    
    init(
        hash: Hash.Type,
        username: String,
        password: String,
        nonce: String? = nil
    ) {
        self.username = username
        self.password = password
        if let nonce = nonce {
            self.clientNonce = nonce
        } else {
            self.clientNonce = Self.generateNonce()
        }
    }
    
    func clientFirstMessage() -> String {
        return "n,,\(clientFirstMessageBare())"
    }
    
    private func clientFirstMessageBare() -> String {
        return "n=\(username),r=\(clientNonce)"
    }
    
    func clientFinalMessage(serverFirstMessage: String) throws -> String {
        let serverFirstMessageParts = extractNameValuePairs(from: serverFirstMessage)
        guard let serverNonce = serverFirstMessageParts["r"] else {
            throw ScramClientError.serverFirstMessageMissingAttribute("r")
        }
        guard let saltString = serverFirstMessageParts["s"] else {
            throw ScramClientError.serverFirstMessageMissingAttribute("s")
        }
        guard let salt = Data(base64Encoded: saltString) else {
            throw ScramClientError.serverFirstMessageSaltIsNotBase64Encoded(saltString)
        }
        guard let iterationCountString = serverFirstMessageParts["i"] else {
            throw ScramClientError.serverFirstMessageMissingAttribute("i")
        }
        guard let iterationCount = Int(iterationCountString) else {
            throw ScramClientError.serverFirstMessageIterationCountIsNotInt(iterationCountString)
        }
        
        guard serverNonce.hasPrefix(clientNonce) else {
            throw ScramClientError.serverFirstMessageNonceNotPrefixedByClientNonce
        }
        
        let saltedPassword = try saltPassword(salt: salt, iterationCount: iterationCount)
        self.saltedPassword = saltedPassword // Store for later verification
        let clientKey = clientKey(saltedPassword: saltedPassword)
        let storedKey = storedKey(clientKey: clientKey)
        let clientFinalMessageWithoutProof = "c=biws,r=\(serverNonce)"
        let authMessageString = "\(clientFirstMessageBare()),\(serverFirstMessage),\(clientFinalMessageWithoutProof)"
        guard let authMessage = authMessageString.data(using: .utf8) else {
            throw ScramClientError.authMessageIsNotUtf8(authMessageString)
        }
        self.authMessage = authMessage // Store for later verification
        let clientSignature = clientSignature(storedKey: storedKey, authMessage: authMessage)
        let clientProof = Data(zip(clientKey, clientSignature).map { $0 ^ $1 }).base64EncodedString()
        let clientFinalMessage = "\(clientFinalMessageWithoutProof),p=\(clientProof)"
        return clientFinalMessage
    }
    
    func validate(serverFinalMessage: String) throws {
        let serverFinalMessageParts = extractNameValuePairs(from: serverFinalMessage)
        if let error = serverFinalMessageParts["e"] {
            throw ScramClientError.authError(error)
        }
        guard let actualServerSignature = serverFinalMessageParts["v"] else {
            throw ScramClientError.serverFinalMessageMissingAttribute("v")
        }
        guard
            let authMessage = self.authMessage,
            let saltedPassword = self.saltedPassword
        else {
            throw ScramClientError.validateCalledBeforeClientFinalMessage
        }
        let serverKey = serverKey(saltedPassword: saltedPassword)
        let expectedServerSignature = serverSignature(serverKey: serverKey, authMessage: authMessage)
        
        if actualServerSignature != expectedServerSignature.base64EncodedString() {
            throw ScramClientError.serverFinalMessageDoesNotMatchExpected
        }
    }
    
    private func saltPassword(salt: Data, iterationCount: Int) throws -> Data {
        guard let passwordData = password.data(using: .ascii) else {
            throw ScramClientError.passwordIsNotAscii(password)
        }
        var saltData = salt
        saltData.append(contentsOf: [0, 0, 0, 1])
        
        let key = SymmetricKey(data: passwordData)
        var Ui = hmac(key: key, data: saltData)
        var Hi = Ui
        for _ in 2 ... iterationCount {
            Ui = hmac(key: key, data: Ui)
            Hi = Data(zip(Hi, Ui).map { $0 ^ $1 })
        }
        return Hi
    }
    
    private func clientKey(saltedPassword: Data) -> Data {
        return hmac(key: saltedPassword, data: clientKeyData)
    }
    
    private func serverKey(saltedPassword: Data) -> Data {
        return hmac(key: saltedPassword, data: serverKeyData)
    }
    
    private func storedKey(clientKey: Data) -> Data {
        var hash = Hash()
        hash.update(data: clientKey)
        return Data(hash.finalize())
    }
    
    private func clientSignature(storedKey: Data, authMessage: Data) -> Data {
        return hmac(key: storedKey, data: authMessage)
    }
    
    private func serverSignature(serverKey: Data, authMessage: Data) -> Data {
        return hmac(key: serverKey, data: authMessage)
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        return hmac(key: SymmetricKey(data: key), data: data)
    }
    
    private func hmac(key: SymmetricKey, data: Data) -> Data {
        var hmac = HMAC<Hash>(key: key)
        hmac.update(data: data)
        return Data(hmac.finalize())
    }
    
    private static func generateNonce() -> String {
        let nonceLen = 16
        let nonceData = (0..<nonceLen).reduce(into: Data()) { data, _ in
            // Any printable ascii (33 - 126) excluding ',' (44)
            var asciiCode = UInt8.random(in: 33 ... 125)
            if asciiCode > 43 {
                asciiCode += 1
            }
            data.append(asciiCode)
        }
        // Force unwrap is guaranteed because of byte control above.
        var clientNonce = String(data: nonceData, encoding: .utf8)!
        clientNonce = clientNonce.encodeBase64UrlSafe()
        return clientNonce
    }
}

enum ScramClientError: Error {
    case authError(String)
    case authMessageIsNotUtf8(String)
    case passwordIsNotAscii(String)
    case serverFirstMessageMissingAttribute(String)
    case serverFirstMessageSaltIsNotBase64Encoded(String)
    case serverFirstMessageIterationCountIsNotInt(String)
    case serverFirstMessageNonceNotPrefixedByClientNonce
    case serverFinalMessageMissingAttribute(String)
    case serverFinalMessageDoesNotMatchExpected
    case validateCalledBeforeClientFinalMessage
}
