import Foundation

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
    
    public func toZinc() -> String {
        var zinc = "@\(val)"
        if let dis = dis {
            zinc += " \(dis)"
        }
        return zinc
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#ref
extension Ref {
    static let kindValue = "ref"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
        case dis
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(val, forKey: .val)
        try container.encode(dis, forKey: .dis)
    }
}

public enum RefError: Error {
    case invalidCharacterInRef(Character, String)
}

