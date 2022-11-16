import Foundation

/// Bool is the truth data type with the two values `true` and `false`.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#bool)
extension Bool: Val {
    public static var valType: ValType { .Bool }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        return self ? "T" : "F"
    }
}

extension Bool: Comparable {
    public static func < (lhs: Bool, rhs: Bool) -> Bool {
        return !lhs && rhs // false is less than true
    }
}
