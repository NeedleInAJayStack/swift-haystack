import Foundation

public struct XStr: Val {
    public static var valType: ValType { .XStr }
    
    public let type: String
    public let val: String
    
    public init(type: String, val: String) throws {
        try type.validateXStrTypeName()
        self.type = type
        self.val = val
    }
    
    public func toZinc() -> String {
        return "\(type)(\"\(val)\")"
    }
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
            
            try self.init(
                type: container.decode(String.self, forKey: .type),
                val: container.decode(String.self, forKey: .val)
            )
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

extension String {
    func validateXStrTypeName() throws {
        guard let firstChar = self.first else {
            throw XStrError.cannotBeEmptyString
        }
        guard firstChar.isUppercase else {
            throw XStrError.leadingCharacterIsNotUpperCase(self)
        }
        for char in self {
            guard char.isTagChar else {
                throw XStrError.invalidCharacter(char, self)
            }
        }
    }
}

enum XStrError: Error {
    case cannotBeEmptyString
    case leadingCharacterIsNotUpperCase(String)
    case invalidCharacter(Character, String)
}

