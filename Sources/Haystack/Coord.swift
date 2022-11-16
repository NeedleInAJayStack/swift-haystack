import Foundation

/// Coord is a specialized data type to represent a geographic coordinate as a latitude and longitude.
/// Haystack uses a special atomic type for coordinates to optimize historization of geolocation for
/// transportation applications (versus a collection data type such as dict).
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#coord)
public struct Coord: Val {
    public static var valType: ValType { .Coord }
    
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) throws {
        guard -90 <= latitude, latitude <= 90, -180 <= longitude, longitude <= 180 else {
            throw CoordError.invalidCoordinates(lat: latitude, lng: longitude)
        }
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return "C(\(latitude),\(longitude))"
    }
}

extension Coord: Codable {
    static let kindValue = "coord"
    
    enum CodingKeys: CodingKey {
        case _kind
        case lat
        case lng
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#coord)
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
                latitude: container.decode(Double.self, forKey: .lat),
                longitude: container.decode(Double.self, forKey: .lng)
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
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#coord)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(latitude, forKey: .lat)
        try container.encode(longitude, forKey: .lng)
    }
}

public enum CoordError: Error {
    case invalidCoordinates(lat: Double, lng: Double)
}
