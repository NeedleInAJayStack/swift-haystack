import Foundation

/// Singleton `NA` instance
public let na = NA()

public struct NA: Val {
    public static var valType: ValType { .NA }
    
    public static var val: Self {
        return na
    }
    
    public func toZinc() -> String {
        return "NA"
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#na
extension NA {
    static let kindValue = "na"
    
    enum CodingKeys: CodingKey {
        case _kind
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
            self = na
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "NA representation must be an object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
    }
}
