
public enum ValError: Error {
    case cannotBeCoerced(String, ValType)
    case invalidDateDefinition
    case invalidDateFormat(String)
    case invalidDateTimeDefinition
    case invalidDateTimeFormat(String)
    case invalidTimeDefinition
    case invalidTimeFormat(String)
}
