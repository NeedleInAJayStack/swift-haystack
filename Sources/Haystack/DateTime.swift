import Foundation

public struct DateTime: Val {
    public static var valType: ValType { .DateTime }
    public static let utcName = "UTC"
    
    public let date: Foundation.Date
    public let gmtOffset: Int
    public let timezone: String
    
    public init(date: Foundation.Date) {
        self.date = date
        self.gmtOffset = 0
        self.timezone = Self.utcName
    }
    
    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        millisecond: Int = 0,
        gmtOffset: Int = 0,
        timezone: String = Self.utcName
    ) throws {
        let components = DateComponents(
            calendar: calendar,
            timeZone: .init(secondsFromGMT: gmtOffset),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: millisecond * 1_000_000
        )
        guard let date = components.date else {
            throw ValError.invalidDateTimeDefinition
        }
        self.date = date
        self.gmtOffset = gmtOffset
        self.timezone = timezone
    }
    
    public init(
        date: Date,
        time: Time,
        gmtOffset: Int = 0,
        timezone: String = Self.utcName
    ) throws {
        let components = DateComponents(
            calendar: calendar,
            timeZone: .init(secondsFromGMT: gmtOffset),
            year: date.year,
            month: date.month,
            day: date.day,
            hour: time.hour,
            minute: time.minute,
            second: time.second,
            nanosecond: time.millisecond * 1_000_000
        )
        guard let date = components.date else {
            throw ValError.invalidDateTimeDefinition
        }
        self.date = date
        self.gmtOffset = gmtOffset
        self.timezone = timezone
    }
    
    public init(_ string: String) throws {
        let splits = string.split(separator: " ")
        let isoString = String(splits[0])
        let (date, gmtOffset) = try Self.dateFromString(isoString)
        self.date = date
        self.gmtOffset = gmtOffset
        if splits.count > 1 {
            self.timezone = String(splits[1])
        } else {
            self.timezone = Self.utcName
        }
    }
    
    public func toZinc() -> String {
        var zinc: String
        if hasMilliseconds {
            zinc = dateTimeWithMillisFormatter.string(from: date)
        } else {
            zinc = dateTimeFormatter.string(from: date)
        }
        if timezone != Self.utcName {
            zinc += " \(timezone)"
        }
        return zinc
    }
    
    static func dateFromString(_ isoString: String) throws -> (Foundation.Date, Int) {
        // Must use Regex so we can preserve GMT offset details. dateFormatter doesn't give us this
        let expr = try NSRegularExpression(pattern: #"(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2}\.?\d*)([+-]\d{2}:\d{2}|Z)"#)
        guard let match = expr.firstMatch(
            in: isoString,
            range: NSRange(isoString.startIndex..<isoString.endIndex, in: isoString)
        ) else {
            throw ValError.invalidDateTimeFormat(isoString)
        }
        
        guard
            let dateRange = Range(match.range(at: 1), in: isoString),
            let timeRange = Range(match.range(at: 2), in: isoString),
            let offsetRange = Range(match.range(at: 3), in: isoString)
        else {
            throw ValError.invalidDateTimeFormat(isoString)
        }
        
        let date = try Date(String(isoString[dateRange]))
        let time = try Time(String(isoString[timeRange]))
        let offsetStr = String(isoString[offsetRange])
        
        let gmtOffset: Int
        if offsetStr == "Z" {
            gmtOffset = 0
        } else {
            let offsetExpr = try NSRegularExpression(pattern: #"([+-])(\d{2}):(\d{2})"#)
            guard let offsetMatch = offsetExpr.firstMatch(
                in: offsetStr,
                range: NSRange(offsetStr.startIndex..<offsetStr.endIndex, in: offsetStr)
            ) else {
                throw ValError.invalidDateTimeFormat(isoString)
            }
            
            guard
                let symbolRange = Range(offsetMatch.range(at: 1), in: offsetStr),
                let hourRange = Range(offsetMatch.range(at: 2), in: offsetStr),
                let minuteRange = Range(offsetMatch.range(at: 3), in: offsetStr),
                let hour = Int(String(offsetStr[hourRange])),
                let minute = Int(String(offsetStr[minuteRange]))
            else {
                throw ValError.invalidDateTimeFormat(isoString)
            }
            let sign = String(offsetStr[symbolRange]) == "+" ? 1 : -1
            
            gmtOffset = sign * ((hour * 60 * 60) + (minute * 60))
        }
        
        let components = DateComponents(
            calendar: calendar,
            timeZone: .init(secondsFromGMT: gmtOffset),
            year: date.year,
            month: date.month,
            day: date.day,
            hour: time.hour,
            minute: time.minute,
            second: time.second,
            nanosecond: time.millisecond * 1_000_000
        )
        guard let date = components.date else {
            throw ValError.invalidDateTimeDefinition
        }
        
        return (date, gmtOffset)
        
//        if let date = dateTimeFormatter.date(from: isoString) {
//            return date
//        } else if let date = dateTimeWithMillisFormatter.date(from: isoString) {
//            return date
//        } else {
//            throw ValError.invalidDateTimeFormat(isoString)
//        }
    }
    
    private var hasMilliseconds: Bool {
        return calendar.component(.nanosecond, from: date) != 0
    }
    
    /// Singleton Haystack DateTime formatter
    var dateTimeFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .init(secondsFromGMT: gmtOffset)
        return formatter
    }

    /// Singleton Haystack DateTime formatter with fractional second support
    var dateTimeWithMillisFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = .init(secondsFromGMT: gmtOffset)
        return formatter
    }
}

var calendar = Calendar(identifier: .gregorian)

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
        do {
            let (date, gmtOffset) = try Self.dateFromString(isoString)
            self.date = date
            self.gmtOffset = gmtOffset
        } catch {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [Self.CodingKeys.val],
                    debugDescription: "DateTime value in incorrect format: `\"\(isoString)\"`"
                )
            )
        }
        
        let timezone = (try? container.decode(String.self, forKey: .tz)) ?? Self.utcName
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
        if timezone != DateTime.utcName {
            try container.encode(timezone, forKey: .tz)
        }
    }
}
