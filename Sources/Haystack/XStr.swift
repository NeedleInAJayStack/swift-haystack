import Foundation

public struct XStr: Val {
    public var valType: ValType { .XStr }
    
    let type: String
    let val: String
}

/// See https://project-haystack.org/doc/docHaystack/Json#xstr
extension XStr {
    static let kindValue = "xstr"
    
    enum CodingKeys: CodingKey {
        case _kind
        case type
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
            
            self.type = try container.decode(String.self, forKey: .type)
            self.val = try container.decode(String.self, forKey: .val)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "XStr representation must be an object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(type, forKey: .type)
        try container.encode(val, forKey: .val)
    }
}
