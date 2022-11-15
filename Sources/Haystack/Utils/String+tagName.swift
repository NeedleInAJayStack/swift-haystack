import Foundation

extension String {
    func validateTagName() throws {
        guard let firstChar = self.first else {
            throw TagNameError.cannotBeEmptyString
        }
        guard firstChar.isLowercase else {
            throw TagNameError.leadingCharacterIsNotLowerCase(self)
        }
        for char in self {
            guard char.isTagChar else {
                throw TagNameError.invalidCharacter(char, self)
            }
        }
    }
}

extension Character {
    var isTagChar: Bool {
        return
            "a" <= self && self <= "z" ||
            "A" <= self && self <= "Z" ||
            "0" <= self && self <= "9" ||
            self == "_"
    }
}

enum TagNameError: Error {
    case cannotBeEmptyString
    case leadingCharacterIsNotLowerCase(String)
    case invalidCharacter(Character, String)
}
