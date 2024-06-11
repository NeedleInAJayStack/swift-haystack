/// Query-able DateTime ranges, which support relative and absolute values.
public enum HisReadRange {
    case today
    case yesterday
    case date(Haystack.Date)
    case dateRange(from: Haystack.Date, to: Haystack.Date)
    case dateTimeRange(from: DateTime, to: DateTime)
    case after(DateTime)
}
