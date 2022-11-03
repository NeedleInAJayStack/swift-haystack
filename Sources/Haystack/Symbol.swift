import Foundation

public struct Symbol: Val {
    public static var valType: ValType { .Symbol }
    
    public let val: String
    
    public init(val: String) {
        self.val = val
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#symbol
extension Symbol {
    static let kindValue = "symbol"
    
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
                    debugDescription: "Symbol representation must be an object"
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
