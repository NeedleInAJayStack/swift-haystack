import Foundation

/// Singleton `Marker` instance
public let marker = Marker()

/// Marker is a singleton used to create "label" tags. Markers are used to express typing information.
/// For example the equip tag is used on any dict that represents an equipment asset.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#marker)
public struct Marker: Val {
    public static var valType: ValType { .Marker }
    
    /// Singleton `Marker` instance
    public static var val: Self {
        return marker
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "M"
    }
}

extension Marker {
    static let kindValue = "marker"
    
    enum CodingKeys: CodingKey {
        case _kind
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#marker)
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
            self = marker
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Marker representation must be an object"
                )
            )
        }
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#marker)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
    }
}
