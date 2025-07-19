import Foundation

/// Query-able DateTime ranges, which support relative and absolute values.
public enum HisReadRange: Sendable {
    case today
    case yesterday
    case date(Haystack.Date)
    case dateRange(from: Haystack.Date, to: Haystack.Date)
    case dateTimeRange(from: DateTime, to: DateTime)
    case after(DateTime)

    public func start() -> Foundation.Date? {
        switch self {
        case .today:
            return Calendar.current.startOfDay(for: Foundation.Date())
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Foundation.Date()))!
        case let .date(date):
            return date.startOfDay(timezone: nil)
        case let .dateRange(from, _):
            return from.startOfDay(timezone: nil)
        case let .dateTimeRange(from, _):
            return from.date
        case let .after(from):
            return from.date
        }
    }

    public func end() -> Foundation.Date? {
        switch self {
        case .today:
            return Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Foundation.Date()))!
        case .yesterday:
            return Calendar.current.startOfDay(for: Foundation.Date())
        case let .date(date):
            return date.endOfDay(timezone: nil)
        case let .dateRange(_, to):
            return to.endOfDay(timezone: nil)
        case let .dateTimeRange(_, to):
            return to.date
        case .after:
            return nil
        }
    }

    public static func fromZinc(_ str: String) throws -> HisReadRange {
        if str == "today" {
            return .today
        }
        if str == "yesterday" {
            return .yesterday
        }
        if str.contains(",") {
            let split = str.split(separator: ",")
            let fromStr = String(split[0])
            let fromVal = try? ZincReader(fromStr).readVal()
            let toStr = String(split[1])
            let toVal = try? ZincReader(toStr).readVal()

            switch fromVal {
            case let fromDate as Haystack.Date:
                switch toVal {
                case let toDate as Haystack.Date:
                    return .dateRange(from: fromDate, to: toDate)
                default:
                    throw HisReadRangeError.fromAndToDontMatch(fromStr, toStr)
                }
            case let fromDateTime as DateTime:
                switch toVal {
                case let toDateTime as DateTime:
                    return .dateTimeRange(from: fromDateTime, to: toDateTime)
                default:
                    throw HisReadRangeError.fromAndToDontMatch(fromStr, toStr)
                }
            default:
                throw HisReadRangeError.formatNotRecognized(str)
            }
        }
        let val = try? ZincReader(str).readVal()
        switch val {
        case let date as Haystack.Date:
            return .date(date)
        case let dateTime as DateTime:
            return .after(dateTime)
        default:
            throw HisReadRangeError.formatNotRecognized(str)
        }
    }

    public func toZinc() throws -> String {
        switch self {
        case .today:
            return "today"
        case .yesterday:
            return "yesterday"
        case let .date(date):
            return date.toZinc()
        case let .dateRange(from, to):
            return "\(from.toZinc()),\(to.toZinc())"
        case let .dateTimeRange(from, to):
            return "\(from.toZinc()),\(to.toZinc())"
        case let .after(dateTime):
            return dateTime.toZinc()
        }
    }
}

enum HisReadRangeError: Error {
    case fromAndToDontMatch(String, String)
    case formatNotRecognized(String)
}
