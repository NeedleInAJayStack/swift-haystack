import Foundation

public struct Date: Val {
    public static var valType: ValType { .Date }
    
    // TODO: Ensure no sub-day components
    public let date: Foundation.Date
    
    public init(date: Foundation.Date) {
        self.date = date
    }
    
    public func toZinc() -> String {
        return dateFormatter.string(from: date)
    }
}

/// Singleton Haystack Date formatter
var dateFormatter: ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withColonSeparatorInTime]
    return formatter
}

/// See https://project-haystack.org/doc/docHaystack/Json#date
extension Date {
    static let kindValue = "date"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
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
            
            let isoString = try container.decode(String.self, forKey: .val)
            guard let date = dateFormatter.date(from: isoString) else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys.val],
                        debugDescription: "Date value in incorrect format: `\"\(isoString)\"`"
                    )
                )
            }
            self.date = date
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Date representation must be an object"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        let isoString = dateFormatter.string(from: self.date)
        try container.encode(isoString, forKey: .val)
    }
}
