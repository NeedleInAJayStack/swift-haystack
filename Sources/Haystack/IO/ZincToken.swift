import Foundation

enum ZincToken: String, Equatable, Hashable {
    case eof

    // literals
    case id = "identifier"
    case num = "Number"
    case str = "Str"
    case ref = "Ref"
    case symbol = "Symbol"
    case uri = "Uri"
    case date = "Date"
    case time = "Time"
    case datetime = "DateTime"

    // syntax
    case colon = ":"
    case comma = ","
    case semicolon = ";"
    case minus = "-"
    case eq = "=="
    case notEq = "!="
    case lt = "<"
    case lt2 = "<<"
    case ltEq = "<="
    case gt = ">"
    case gt2 = ">>"
    case gtEq = ">="
    case lbracket = "["
    case rbracket = "]"
    case lbrace = "{"
    case rbrace = "}"
    case lparen = "("
    case rparen = ")"
    case arrow = "->"
    case slash = "/"
    case assign = "="
    case bang = "!"
    case nl = "newline"

    var dis: String {
        return rawValue
    }

    var isLiteral: Bool {
        switch self {
        case .num, .str, .ref, .symbol, .uri, .date, .time, .datetime:
            return true
        default:
            return false
        }
    }
}
