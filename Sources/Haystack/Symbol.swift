import Foundation

/// Symbols are the data type for
/// [def](https://project-haystack.org/doc/docHaystack/Defs) identifiers.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#symbol)
public struct Symbol: Val {
    public static var valType: ValType { .Symbol }
    
    public let val: String
    
    public init(_ val: String) throws {
        for char in val {
            guard char.isIdChar else {
                throw SymbolError.invalidCharacterInSymbol(char, val)
            }
        }
        self.val = val
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "^\(val)"
    }
}

extension Symbol {
    static let kindValue = "symbol"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#symbol)
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
            
            try self.init(container.decode(String.self, forKey: .val))
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
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#symbol)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(val, forKey: .val)
    }
}

public enum SymbolError: Error {
    case leadingCharacterIsNotLowerCase(String)
    case invalidCharacterInSymbol(Character, String)
}
