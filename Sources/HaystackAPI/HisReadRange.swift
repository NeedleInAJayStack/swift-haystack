import Haystack

/// Query-able DateTime ranges, which support relative and absolute values.
public enum HisReadRange {
    case today
    case yesterday
    case date(Haystack.Date)
    case dateRange(from: Haystack.Date, to: Haystack.Date)
    case dateTimeRange(from: DateTime, to: DateTime)
    case after(DateTime)
    
    public func toString() -> String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case let .date(date): return "\(date.toZinc())"
        case let .dateRange(fromDate, toDate): return "\(fromDate.toZinc()),\(toDate.toZinc())"
        case let .dateTimeRange(fromDateTime, toDateTime): return "\(fromDateTime.toZinc()),\(toDateTime.toZinc())"
        case let .after(dateTime): return "\(dateTime.toZinc())"
        }
    }
}
