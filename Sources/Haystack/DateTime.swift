import Foundation

public struct DateTime: Val {
    public static var valType: ValType { .DateTime }
    public static let gmtName = "GMT"
    
    public let date: Foundation.Date
    public let timezone: String // TODO: Align with Foundation.TimeZone
    
    public init(date: Foundation.Date, timezone: String) {
        self.date = date
        self.timezone = timezone
    }
}

/// Singleton Haystack DateTime formatter
var dateTimeFormatter: ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}

/// Singleton Haystack DateTime formatter
var dateTimeWithMillisFormatter: ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}

/// See https://project-haystack.org/doc/docHaystack/Json#dateTime
extension DateTime {
    static let kindValue = "dateTime"
    
    enum CodingKeys: CodingKey {
        case _kind
        case val
        case tz
    }
    
    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: Self.CodingKeys) else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Date representation must be an object"
                )
            )
        }
        
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
        if let date = dateTimeFormatter.date(from: isoString) {
            self.date = date
        } else if let date = dateTimeWithMillisFormatter.date(from: isoString) {
            self.date = date
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [Self.CodingKeys.val],
                    debugDescription: "DateTime value in incorrect format: `\"\(isoString)\"`"
                )
            )
        }
        
        let timezone = (try? container.decode(String.self, forKey: .tz)) ?? Self.gmtName
        self.timezone = timezone
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        let isoString: String
        if hasMilliseconds {
            isoString = dateTimeWithMillisFormatter.string(from: self.date)
        } else {
            isoString = dateTimeFormatter.string(from: self.date)
        }
        try container.encode(isoString, forKey: .val)
        if timezone != DateTime.gmtName {
            try container.encode(timezone, forKey: .tz)
        }
    }
    
    private var hasMilliseconds: Bool {
        return date.timeIntervalSinceReferenceDate.remainder(dividingBy: 1.0) != 0.0
    }
}
