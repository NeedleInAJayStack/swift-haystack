import Foundation

public struct Uri: Val {
    public static var valType: ValType { .Uri }
    
    public let val: String
    
    public init(val: String) {
        self.val = val
    }
    
    public func toZinc() -> String {
        return "`\(val)`"
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#uri
extension Uri {
    static let kindValue = "uri"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
    }
    
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(val, forKey: .val)
    }
}
