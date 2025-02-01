import Foundation

/// Query-able DateTime ranges, which support relative and absolute values.
public enum HisReadRange {
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
        case .after(_):
            return nil
        }
    }
}
