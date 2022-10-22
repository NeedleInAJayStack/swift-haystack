import Foundation

extension Bool: HVal {
    public func toZinc() -> String {
        return self ? "T" : "F"
    }
}

extension Bool: Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        return !lhs && rhs // false is less than true
    }
}
