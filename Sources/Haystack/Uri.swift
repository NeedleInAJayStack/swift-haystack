import Foundation

/// Uri is the data type used to represent Universal Resource Identifiers according to
/// [RFC 3986](http://tools.ietf.org/html/rfc3986).
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#uri)
public struct Uri: Val {
    public static var valType: ValType { .Uri }
    
    public let val: String
    
    public init(_ val: String) {
        self.val = val
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "`\(val)`"
    }
}

// Uri + Codable
extension Uri {
    static let kindValue = "uri"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#uri)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Self.CodingKeys) {
            guard try container.decode(String.self, forKey: ._kind) == Self.kindValue else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys._kind],
                        debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                    )
                )
            }
            
            self.val = try container.decode(String.self, forKey: .val)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Uri representation must be an object"
                )
            )
        }
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#uri)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(val, forKey: .val)
    }
}
