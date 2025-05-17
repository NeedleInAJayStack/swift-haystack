import Foundation

extension Character {
    /// Is valid [identifier reference](https://project-haystack.org/doc/docHaystack/Kinds#ref)
    /// character
    var isIdChar: Bool {
        return
            self >= "a" && self <= "z" ||
            self >= "A" && self <= "Z" ||
            self >= "0" && self <= "9" ||
            self == "_" ||
            self == ":" ||
            self == "-" ||
            self == "." ||
            self == "~"
    }
}
