import Foundation

public struct Coord: Val {
    public static var valType: ValType { .Coord }
    
    public let lat: Double
    public let lng: Double
    
    public init(lat: Double, lng: Double) throws {
        guard -90 <= lat, lat <= 90, -180 <= lng, lng <= 180 else {
            throw CoordError.invalidCoordinates(lat: lat, lng: lng)
        }
        self.lat = lat
        self.lng = lng
    }
    
    public func toZinc() -> String {
        return "C(\(lat),\(lng))"
    }
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
            
            try self.init(
                lat: container.decode(Double.self, forKey: .lat),
                lng: container.decode(Double.self, forKey: .lng)
            )
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

public enum CoordError: Error {
    case invalidCoordinates(lat: Double, lng: Double)
}
