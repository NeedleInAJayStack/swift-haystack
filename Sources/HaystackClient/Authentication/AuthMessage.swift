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
