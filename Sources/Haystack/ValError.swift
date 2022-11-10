
public enum ValError: Error {
    case invalidDateDefinition
    case invalidDateFormat(String)
    case invalidDateTimeDefinition
    case invalidDateTimeFormat(String)
    case invalidTimeFormat(String)
}
