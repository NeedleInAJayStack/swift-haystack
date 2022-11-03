import Foundation

/// Singleton `Marker` instance
let marker = Marker()

struct Marker: Val {
    public static var valType: ValType { .Marker }
}

/// See https://project-haystack.org/doc/docHaystack/Json#marker
extension Marker {
    static let kindValue = "marker"
    
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
    }
}
