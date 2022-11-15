import Foundation

/// Singleton `remove` instance
public let remove = Remove()

/// Remove is a singleton used in dicts to indicate removal of a tag. It is reserved for future HTTP ops that perform entity updates.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#remove)
public struct Remove: Val {
    public static var valType: ValType { .Remove }
    
    public func toZinc() -> String {
        return "R"
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#remove
extension Remove {
    static let kindValue = "remove"
    
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
            self = remove
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Remove representation must be an object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
    }
}
