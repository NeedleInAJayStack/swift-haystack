import Foundation

/// Refs are the data type for instance data identifiers. All entities are identified via the id tag and a unique
/// ref data value. Relationships cross-reference the entity with ref tags. And, operations such as the read
/// or hisRead ops will identify the entity with its ref id.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#ref)
public struct Ref: Val {
    public static var valType: ValType { .Ref }

    public let val: String
    public let dis: String?

    public init(_ val: String, dis: String? = nil) throws {
        for char in val {
            guard char.isIdChar else {
                throw RefError.invalidCharacterInRef(char, val)
            }
        }
        self.val = val
        self.dis = dis
    }

    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        var zinc = "@\(val)"
        if let dis = dis {
            zinc += " \(dis)"
        }
        return zinc
    }
}

// Ref + Codable
extension Ref {
    static let kindValue = "ref"

    enum CodingKeys: CodingKey {
        case _kind
        case val
        case dis
    }

    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#ref)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Self.CodingKeys.self) {
            guard try container.decode(String.self, forKey: ._kind) == Self.kindValue else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys._kind],
                        debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                    )
                )
            }

            try self.init(
                container.decode(String.self, forKey: .val),
                dis: container.decode(String?.self, forKey: .dis)
            )
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Ref representation must be an object"
                )
            )
        }
    }

    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#ref)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys.self)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(val, forKey: .val)
        try container.encode(dis, forKey: .dis)
    }
}

public enum RefError: Error {
    case invalidCharacterInRef(Character, String)
}
