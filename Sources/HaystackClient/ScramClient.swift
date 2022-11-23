import CryptoKit
import Foundation

@available(macOS 10.15, *)
/// A Salted Challenge Response Authentication Mechanism (SCRAM) Client that is compatible with
/// [RFC 5802](https://www.rfc-editor.org/rfc/rfc5802)
class ScramClient<Hash: HashFunction> {
    private let clientKeyData = "Client Key".data(using: .utf8)!
    
    private let username: String
    private let password: String
    private let clientNonce: String
    
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
            throw ScramClientError.serverFirstMessageSaltCannotBeEncoded(saltString)
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
        let clientKey = clientKey(saltedPassword: saltedPassword)
        let storedKey = storedKey(clientKey: clientKey)
        let clientFinalMessageWithoutProof = "c=biws,r=\(serverNonce)"
        let authMessage = "\(clientFirstMessageBare()),\(serverFirstMessage),\(clientFinalMessageWithoutProof)"
        guard let authMessageData = authMessage.data(using: .utf8) else {
            throw ScramClientError.authMessageIsNotUtf8(authMessage)
        }
        let clientSignature = clientSignature(storedKey: storedKey, authMessage: authMessageData)
        let clientProof = Data(zip(clientKey, clientSignature).map { $0 ^ $1 }).base64EncodedString()
        
        let clientFinalMessage = "\(clientFinalMessageWithoutProof),p=\(clientProof)"
        return clientFinalMessage
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
        var hmac = HMAC<Hash>(key: SymmetricKey(data: saltedPassword))
        hmac.update(data: clientKeyData)
        return Data(hmac.finalize())
    }
    
    private func storedKey(clientKey: Data) -> Data {
        var hash = Hash()
        hash.update(data: clientKey)
        return Data(hash.finalize())
    }
    
    private func clientSignature(storedKey: Data, authMessage: Data) -> Data {
        return hmac(key: storedKey, data: authMessage)
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

func extractNameValuePairs(from fieldsString: String) -> [String: String] {
    // Example input: "hash=SHA-256, handshakeToken=aabbcc"
    var attributes = [String: String]()
    for pair in fieldsString.split(separator: ",") {
        // If "=" does not exist, just parse the entire section as the name, and the value is ""
        let assnIndex = pair.firstIndex(of: "=") ?? pair.endIndex
        let name = String(pair[..<assnIndex]).trimmingCharacters(in: .whitespaces)
        var value = String(pair[assnIndex...]).trimmingCharacters(in: .whitespaces)
        value.removeFirst()
        
        attributes[name] = value
    }
    return attributes
}

enum ScramClientError: Error {
    case authMessageIsNotUtf8(String)
    case passwordIsNotAscii(String)
    case serverFirstMessageMissingAttribute(String)
    case serverFirstMessageSaltCannotBeEncoded(String)
    case serverFirstMessageIterationCountIsNotInt(String)
    case serverFirstMessageNonceNotPrefixedByClientNonce
}
