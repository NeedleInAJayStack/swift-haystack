import Foundation

extension Character {
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
