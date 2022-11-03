import Foundation

public struct Coord: Val {
    public static var valType: ValType { .Coord }
    
    let lat: Double
    let lng: Double
}

/// See https://project-haystack.org/doc/docHaystack/Json#coord
extension Coord: Codable {
    static let kindValue = "coord"
    
    enum CodingKeys: CodingKey {
        case _kind
        case lat
        case lng
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
            
            self.lat = try container.decode(Double.self, forKey: .lat)
            self.lng = try container.decode(Double.self, forKey: .lng)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Coord representation must be an object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }
}
