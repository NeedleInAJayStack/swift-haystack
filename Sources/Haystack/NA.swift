import Foundation

/// Singleton `NA` instance
public let na = NA()

/// NA is a singleton for not available. It fills a similar role as the NA constant in the R language as a place holding for
/// missing or invalid data values. In Haystack it is most often used in historized data to indicate that a timestamp
/// sample is in error.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#na)
public struct NA: Val {
    public static var valType: ValType { .NA }
    
    public static var val: Self {
        return na
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "NA"
    }
}

// NA + Codable
extension NA {
    static let kindValue = "na"
    
    enum CodingKeys: CodingKey {
        case _kind
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#na)
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
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#na)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
    }
}
