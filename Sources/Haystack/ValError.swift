
public enum ValError: Error {
    case invalidDateDefinition
    case invalidDateFormat(String)
    case invalidTimeFormat(String)
}
