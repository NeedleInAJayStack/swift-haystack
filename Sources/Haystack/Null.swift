import Foundation

/// Singleton `null` instance
public let null = Null()

/// Null is a value that maps to Haystack's null value, which is not formally defined. In some cases,
/// (such as JSON coding), it is more convenient to work with a specific type instead of bridging
/// Swift's nil.
public struct Null: Val {
    public static var valType: ValType { .Null }
    
    public static var val: Self {
        return null
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "N"
    }
}

extension Null {
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#v4)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            guard container.decodeNil() else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [],
                        debugDescription: "Expected Null JSON to be `null`"
                    )
                )
            }
            self = null
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Null representation must be a scalar"
                )
            )
        }
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#v4)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
