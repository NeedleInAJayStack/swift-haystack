import Foundation

/// Number is an integer or floating point value with an optional unit of measurement. Implementations should represent
/// a number as a 64-bit IEEE 754 floating point and provide 52 bits of lossless integer representation.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#number)
public struct Number: Val {
    public static var valType: ValType { .Number }

    public static var infinity: Self {
        return Number(.infinity)
    }

    public static var negativeInfinity: Self {
        return Number(-1 * .infinity)
    }

    public static var nan: Self {
        return Number(.nan)
    }

    public let val: Double
    public let unit: String?

    public init(_ val: Double, unit: String? = nil) {
        self.val = val
        self.unit = unit
    }

    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        guard !val.isNaN else {
            return "NaN"
        }
        guard val.isFinite else {
            if val == Double.infinity {
                return "INF"
            } else {
                return "-INF"
            }
        }

        var zinc: String
        if val.remainder(dividingBy: 1.0) == .zero {
            zinc = String(format: "%.f", val)
        } else {
            zinc = "\(val)"
        }

        if let unit = unit {
            zinc += "\(unit.withZincUnicodeEscaping())"
        }
        return zinc
    }

    public var isInt: Bool {
        return val == val.rounded()
    }
}

// Number + Codable
extension Number {
    static let kindValue = "number"

    enum CodingKeys: CodingKey {
        case _kind
        case val
        case unit
    }

    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#number)
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

            if let val = try? container.decode(Double.self, forKey: .val) {
                self.val = val
                unit = try container.decode(String?.self, forKey: .unit)
            } else if let val = try? container.decode(String.self, forKey: .val) {
                unit = nil
                switch val {
                case "INF":
                    self.val = .infinity
                case "-INF":
                    self.val = -1.0 * .infinity
                case "NaN":
                    self.val = .nan
                default:
                    throw DecodingError.typeMismatch(
                        Self.self,
                        .init(
                            codingPath: [Self.CodingKeys.val],
                            debugDescription: "String `val` must be either `INF`, `-INF`, or `NaN`, not \(val)"
                        )
                    )
                }
            } else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys.val],
                        debugDescription: "Expected `val` to be either Double or String"
                    )
                )
            }
        } else if let container = try? decoder.singleValueContainer() {
            val = try container.decode(Double.self)
            unit = nil
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

    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#number)
    public func encode(to encoder: Encoder) throws {
        if unit != nil || val.isNaN || val.isInfinite {
            var container = encoder.container(keyedBy: Self.CodingKeys.self)
            try container.encode(Self.kindValue, forKey: ._kind)

            if val.isNaN {
                try container.encode("NaN", forKey: .val)
            } else if val.isInfinite {
                if val > 0 {
                    try container.encode("INF", forKey: .val)
                } else {
                    try container.encode("-INF", forKey: .val)
                }
            } else {
                try container.encode(val, forKey: .val)
                try container.encode(unit, forKey: .unit)
            }
        } else {
            var container = encoder.singleValueContainer()
            try container.encode(val)
        }
    }
}

// Number + Equatable
public extension Number {
    static func == (lhs: Number, rhs: Number) -> Bool {
        guard lhs.unit == rhs.unit else {
            return false
        }

        if lhs.val.isNaN {
            return rhs.val.isNaN // Consider 2 NaN numbers as equal
        }

        return lhs.val == rhs.val
    }
}
