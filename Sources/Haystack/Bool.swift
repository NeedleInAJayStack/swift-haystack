import Foundation

extension Bool: Val {
    public var valType: ValType { .Bool }
    
    public func toZinc() -> String {
        return self ? "T" : "F"
    }
}

extension Bool: Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        return !lhs && rhs // false is less than true
    }
}
