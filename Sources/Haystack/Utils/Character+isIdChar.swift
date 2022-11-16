import Foundation

extension Character {
    /// Is valid [identifier reference](https://project-haystack.org/doc/docHaystack/Kinds#ref)
    /// character
    var isIdChar: Bool {
        return
            "a" <= self && self <= "z" ||
            "A" <= self && self <= "Z" ||
            "0" <= self && self <= "9" ||
            self == "_" ||
            self == ":" ||
            self == "-" ||
            self == "." ||
            self == "~"
    }
}
