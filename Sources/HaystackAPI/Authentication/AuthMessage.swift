public struct AuthMessage: CustomStringConvertible {
    public let scheme: String
    public let attributes: [String: String]
    
    public init(scheme: String, attributes: [String : String]) {
        self.scheme = scheme
        self.attributes = attributes
    }
    
    public var description: String {
        // Unwrap is safe because attributes is immutable
        "\(scheme) \(attributes.keys.sorted().map { "\($0)=\(attributes[$0]!)" }.joined(separator: ", "))"
    }
    
    public static func from(_ string: String) throws -> Self {
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

public func extractNameValuePairs(from fieldsString: String) -> [String: String] {
    // Example input: "hash=SHA-256, handshakeToken=aabbcc"
    var attributes = [String: String]()
    for pair in fieldsString.split(separator: ",") {
        // If "=" does not exist, just parse the entire section as the name, and the value is ""
        let assnIndex = pair.firstIndex(of: "=") ?? pair.endIndex
        let name = String(pair[..<assnIndex]).trimmingCharacters(in: .whitespaces)
        var value = String(pair[assnIndex...]).trimmingCharacters(in: .whitespaces)
        if value.count > 0 {
            // Remove "=" prefix
            value.removeFirst()
        }
        
        attributes[name] = value
    }
    return attributes
}
