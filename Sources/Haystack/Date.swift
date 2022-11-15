import Foundation

/// Date is an ISO 8601 calendar date. It is encoded as `YYYY-MM-DD`.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#date)
public struct Date: Val {
    public static var valType: ValType { .Date }
    
    public let year: Int
    public let month: Int
    public let day: Int
    
    public init(
        year: Int,
        month: Int,
        day: Int
    ) throws {
        let components = DateComponents(
            year: year,
            month: month,
            day: day
        )
        guard components.isValidDate(in: calendar) else {
            throw ValError.invalidDateDefinition
        }
        
        self.year = year
        self.month = month
        self.day = day
    }
    
    public init(_ isoString: String) throws {
        let dashSplit = isoString.split(separator: "-")
        guard
            dashSplit.count == 3,
            let year = Int(dashSplit[0]),
            let month = Int(dashSplit[1]),
            let day = Int(dashSplit[2])
        else {
            throw ValError.invalidDateFormat(isoString)
        }
        
        try self.init(
            year: year,
            month: month,
            day: day
        )
    }
    
    public func toZinc() -> String {
        return isoString
    }
    
    var isoString: String {
        let yearStr = String(format: "%04d", arguments: [year])
        let monthStr = String(format: "%02d", arguments: [month])
        let dayStr = String(format: "%02d", arguments: [day])
        return "\(yearStr)-\(monthStr)-\(dayStr)"
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
            do {
                try self.init(isoString)
            } catch {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys.val],
                        debugDescription: "Date value in incorrect format: `\"\(isoString)\"`"
                    )
                )
            }
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
        try container.encode(isoString, forKey: .val)
    }
}
