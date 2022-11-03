import Foundation

public struct Number: Val {
    public static var valType: ValType { .Number }
    
    let val: Double
    let unit: String?
    
    init(val: Double, unit: String? = nil) {
        self.val = val
        self.unit = unit
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#number
extension Number {
    static let kindValue = "number"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
        case unit
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
            
            self.val = try container.decode(Double.self, forKey: .val)
            self.unit = try container.decode(String?.self, forKey: .unit)
        } else if let container = try? decoder.singleValueContainer() {
            self.val = try container.decode(Double.self)
            self.unit = nil
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Number representation must be a scalar or object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if unit != nil || val.isNaN || val.isInfinite {
            var container = encoder.container(keyedBy: Self.CodingKeys)
            try container.encode(Self.kindValue, forKey: ._kind)
            try container.encode(val, forKey: .val)
            try container.encode(unit, forKey: .unit)
        } else {
            var container = encoder.singleValueContainer()
            try container.encode(val)
        }
    }
}
