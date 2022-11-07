import Foundation

class ZincTokenizer {
    var sourceIterator: String.Iterator
    var token: ZincToken = .eof
    var val: any Val = null
    var line: Int = 0
    
    var position: Int = 0
    var cur: ZincCharacter
    var peek: ZincCharacter
    
    init(_ source: String) {
        self.cur = .eof
        self.peek = .eof
        self.sourceIterator = source.makeIterator()
        consume()
        consume()
    }
    
    // MARK: Tokenizing
    
    func next() throws -> ZincToken {
        // reset
        val = null
        
        // skip non-meaningful whitespace and comments
        while true {
            // treat space, tab, non-breaking space as whitespace
            if cur == .char(" ") || cur == .char("\t") {
                consume()
                continue
            }
            if let char = try? cur.character(), char == Character(UnicodeScalar(0xa0)) {
                consume()
                continue
            }
            
            // comments
            if cur == .char("/") {
                if peek == .char("/") {
                    try skipCommentsSL()
                    continue
                }
                if peek == .char("*") {
                    try skipCommentsML()
                    continue
                }
            }
            
            break
        }
        
        // newlines
        if cur == .char("\n") || cur == .char("\r") || cur == .char("\r\n") {
            consume()
            line += 1
            token = .nl
            return token
        }
        
        // handle various starting chars
        if cur.isIdStart() {
            token = try id()
            return token
        }
        if cur == .char("\"") {
            token = try str()
            return token
        }
        if cur == .char("@") {
            token = try ref()
            return token
        }
        if cur == .char("^") {
            token = try symbol()
            return token
        }
        if cur.isDigit() {
            token = try num()
            return token
        }
        if cur == .char("`") {
            token = try uri()
            return token
        }
        if cur == .char("-") && peek.isDigit() {
            token = try num()
            return token
        }
        token = try op()
        return token
    }
    
    // MARK: Token Productions
    
    private func id() throws -> ZincToken {
        var s = ""
        while cur.isIdPart() {
            try s.append(cur.character())
            consume()
        }
        self.val = s
        return ZincToken.id
    }
    
    private func num() throws -> ZincToken {
        // hex number (no unit allowed)
        if cur == .char("0") && peek == .char("x") {
            try consume("0")
            try consume("x")
            var s = ""
            while true {
                if cur.isHex() {
                    try s.append(cur.character())
                    consume()
                    continue
                }
                if cur == .char("_") {
                    consume()
                    continue
                }
                break
            }
            guard let int = Int(s, radix: 16) else {
                throw ZincTokenizerError.invalidHex(s)
            }
            self.val = Number(val: Double(int))
            return .num
        }

        // consume all things that might be part of this number token
        var s = ""
        try s.append(cur.character())
        consume()
        var colons = 0
        var dashes = 0
        var unitIndex: String.Index? = nil
        var exp = false
        while true {
            if !cur.isDigit() {
                if exp && (cur == .char("+") || cur == .char("-")) {
                    
                } else if cur == .char("-") {
                    dashes += 1
                } else if cur == .char(":") && peek.isDigit() {
                    colons += 1
                } else if (exp || colons >= 1) && cur == .char("+") {
                    
                } else if cur == .char(".") {
                    if !peek.isDigit() {
                        break
                    }
                } else if (cur == .char("e") || cur == .char("E")) &&
                            (peek == .char("-") || peek == .char("+") || peek.isDigit()) {
                    exp = true
                } else if cur.isLetter() || cur == .char("%") || cur == .char("$") ||
                            cur == .char("/") ||
                            ((try? cur.character()) ?? " ") > Character(UnicodeScalar(128)) {
                    if (unitIndex == nil) {
                        unitIndex = s.endIndex
                    }
                } else if cur == .char("_") {
                    if unitIndex == nil && peek.isDigit() {
                        consume()
                        continue
                    } else {
                        if (unitIndex == nil) {
                            unitIndex = s.endIndex
                        }
                    }
                } else {
                    break
                }
            }
            try s.append(cur.character())
            consume()
        }

        if dashes == 2 && colons == 0 {
            return try date(s)
        }
        if dashes == 0 && colons >= 1 {
            return try time(s, colons == 1)
        }
        if dashes >= 2 {
            return try dateTime(s)
        }
        return try number(s, unitIndex)
    }
    
    
    private func date(_ s: String) throws -> ZincToken {
        self.val = try Date(s)
        return .date
    }
    
    private func time(_ sIn: String, _ addSeconds: Bool) throws -> ZincToken {
        var s = sIn
        if s.split(separator: ":")[0].count == 1 { // Implies single-value hour
            s = "0\(s)"
        }
        if addSeconds {
            s.append(":00")
        }
        self.val = try Time(s)
        return .time
    }
    
    private func dateTime(_ sIn: String) throws -> ZincToken {
        var s = sIn
        // xxx timezone
        if cur != .char(" ") || !peek.isUppercase() {
            if s.hasSuffix("Z") {
                s.append(" UTC")
            } else {
                throw ZincTokenizerError.expectingTimezone
            }
        } else {
            consume()
            s.append(" ")
            while cur.isIdPart() {
                try s.append(cur.character())
                consume()
            }

            // handle GMT+xx or GMT-xx
            if (cur == .char("+") || cur == .char("-")) && s.hasSuffix("GMT") {
                try s.append(cur.character())
                consume()
                while cur.isDigit() {
                    try s.append(cur.character())
                    consume()
                }
            }
        }
        
        self.val = try DateTime(s)
        return .datetime
    }
    
    private func number(_ s: String, _ unitIndex: String.Index?) throws -> ZincToken {
        guard let unitIndex = unitIndex else {
            guard let double = Double(s) else {
                throw ZincTokenizerError.invalidNumberLiteral(s)
            }
            self.val = Number(val: double)
            return .num
        }
        let doubleStr = s[..<unitIndex]
        let unitStr = s[unitIndex...]
        guard let double = Double(doubleStr) else {
            throw ZincTokenizerError.invalidNumberLiteral(s)
        }
        self.val = Number(val: double, unit: String(unitStr))
        return .num
    }
    
    private func str() throws -> ZincToken {
        try consume("\"")
        var s = ""
        while true {
            if cur == .eof {
                throw ZincTokenizerError.unexpectedEndOfStr
            }
            if cur == .char("\"") {
                try consume("\"")
                break
            }
            if cur == .char("\\") {
                try s.append(String(escape().character()))
                continue
            }
            try s.append(String(cur.character()))
            consume()
        }
        self.val = s
        return .str
    }
    
    private func symbol() throws -> ZincToken {
        try consume("^")
        var s = ""
        while true {
            if let char = try? cur.character(), Ref.isIdChar(char) {
                try s.append(String(cur.character()))
                consume()
            } else {
                break
            }
        }
        guard !s.isEmpty else {
            throw ZincTokenizerError.invalidEmptySymbol
        }
        self.val = Symbol(val: s)
        return .symbol
    }
    
    private func ref() throws -> ZincToken {
        try consume("@")
        var s = ""
        while true {
            if let char = try? cur.character(), Ref.isIdChar(char) {
                try s.append(String(cur.character()))
                consume()
            } else {
                break
            }
        }
        self.val = Ref(val: s)
        return .ref
    }
    
    private func uri() throws -> ZincToken {
        try consume("`")
        var s = ""
        while true {
            if cur == .char("`") {
                try consume("`")
                break
            }
            if cur == .eof || cur == .char("\n") {
                throw ZincTokenizerError.unexpectedEndOfUri
            }
            if cur == .char("\\") {
                switch try peek.character() {
                case ":", "/", "?", "#", "[", "]", "@", "\\", "&", "=", ";":
                    try s.append(String(cur.character()))
                    try s.append(String(peek.character()))
                    consume()
                    consume()
                    break
                default:
                    try s.append(String(escape().character()))
                }
            } else {
                try s.append(String(cur.character()))
                consume()
            }
        }
        self.val = Uri(val: s)
        return .uri
    }

    
    private func escape() throws -> ZincCharacter {
        try consume("\\")
        switch (cur) {
        case let .char(char):
            switch char {
                // TODO: These escaped literals don't appear to be supported in Swift
//            case "b":
//                consume()
//                return .char("\b")
//            case "f":
//                consume()
//                return .char("\f")
            case "n":
                consume()
                return .char("\n")
            case "r":
                consume()
                return .char("\r")
            case "t":
                consume()
                return .char("\t")
            case "\"":
                consume()
                return .char("\"")
            case "$":
                consume()
                return .char("$")
            case "'":
                consume()
                return .char("'")
            case "`":
                consume()
                return .char("`")
            case "\\":
                consume()
                return .char("\\")
            default:
                break
            }
        case .eof:
            throw ZincTokenizerError.unexpectedEndOfFile
        }

        // check for uxxxx
        var esc = ""
        if cur == .char("u") {
            try consume("u")
            try esc.append(String(cur.character()))
            consume()
            try esc.append(String(cur.character()))
            consume()
            try esc.append(String(cur.character()))
            consume()
            try esc.append(String(cur.character()))
            consume()
            guard let code = Int(esc, radix: 16), let scalar = UnicodeScalar(code) else {
                throw ZincTokenizerError.invalidUnicodeEscape(esc)
            }
            return .char(.init(scalar))
        }
        throw ZincTokenizerError.invalidEscapeSequence(cur)
    }
    
    /// parse a symbol token (typically into an operator)
    private func op() throws -> ZincToken {
        let curCopy = cur
        consume()
        switch curCopy {
        case let .char(char):
            switch char {
            case ",": return ZincToken.comma
            case ":": return ZincToken.colon
            case ";": return ZincToken.semicolon
            case "[": return ZincToken.lbracket
            case "]": return ZincToken.rbracket
            case "{": return ZincToken.lbrace
            case "}": return ZincToken.rbrace
            case "(": return ZincToken.lparen
            case ")": return ZincToken.rparen
            case "<":
                if cur == .char("<") {
                    try consume("<")
                    return ZincToken.lt2
                }
                if cur == .char("=") {
                    try consume("=")
                    return ZincToken.ltEq
                }
                return ZincToken.lt
            case ">":
                if cur == .char(">") {
                    try consume(">")
                    return ZincToken.gt2
                }
                if cur == .char("=") {
                    try consume("=")
                    return ZincToken.gtEq
                }
                return ZincToken.gt
            case "-":
                if cur == .char(">") {
                    try consume(">")
                    return ZincToken.arrow
                }
                return ZincToken.minus
            case "=":
                if cur == .char("=") {
                    try consume("=")
                    return ZincToken.eq
                }
                return ZincToken.assign
            case "!":
                if cur == .char("=") {
                    try consume("=")
                    return ZincToken.notEq
                }
                return ZincToken.bang
            case "/":
                return ZincToken.slash
            default: break
            }
        case .eof:
            return ZincToken.eof
        }
        throw ZincTokenizerError.unexpectedSymbol(cur)
    }
    
    // MARK: Comments
    
    private func skipCommentsSL() throws {
        try consume("/")
        try consume("/")
        while (true) {
            if cur == .char("\n") || cur == .eof {
                break
            }
            consume()
        }
    }
    
    private func skipCommentsML() throws {
        try consume("/")
        try consume("*")
        var depth = 1
        while (true) {
            if cur == .char("*"), peek == .char("/") {
                try consume("*")
                try consume("/")
                depth -= 1
                if (depth <= 0) {
                    break
                }
            }
            if cur == .char("/"), peek == .char("*") {
                try consume("/")
                try consume("*")
                depth += 1
                continue
            }
            if cur == .char("\n") {
                line += 1
            }
            if cur == .eof {
                throw ZincTokenizerError.multiLineCommentNotClosed
            }
            consume()
        }
    }
    
    // MARK: Char
    
    private func consume(_ expected: Character) throws {
        if cur != .char(expected) {
            throw ZincTokenizerError.expectationFailed(.char(expected), cur)
        }
        consume()
    }
    
    private func consume() {
        position = position + 1
        cur = peek
        if let newPeek = sourceIterator.next() {
            peek = .char(newPeek)
        } else {
            peek = .eof
        }
    }
}

enum ZincCharacter: Equatable {
    case char(Character)
    case eof
    
    func character() throws -> Character {
        switch self {
        case let .char(char):
            return char
        case .eof:
            throw ZincTokenizerError.unexpectedEndOfFile
        }
    }
    
    func isLetter() -> Bool {
        switch self {
        case let .char(char):
            return char.isLetter
        case .eof:
            return false
        }
    }
    
    func isUppercase() -> Bool {
        switch self {
        case let .char(char):
            return char.isUppercase
        case .eof:
            return false
        }
    }
    
    func isIdStart() -> Bool {
        switch self {
        case let .char(char):
            return ("a" <= char && char <= "z") ||
                ("A" <= char && char <= "Z")
        case .eof:
            return false
        }
    }
    
    func isIdPart() -> Bool {
        if self.isIdStart() || self.isDigit() {
            return true
        }
        switch self {
        case let .char(char):
            return char == "_"
        case .eof:
            return false
        }
    }
    
    func isDigit() -> Bool {
        switch self {
        case let .char(char):
            return ("0" <= char && char <= "9")
        case .eof:
            return false
        }
    }
    
    func isHex() -> Bool {
        if self.isDigit() {
            return true
        }
        switch self {
        case let .char(char):
            let lower = char.lowercased()
            return ("a" <= lower && lower <= "f")
        case .eof:
            return false
        }
    }
}

enum ZincTokenizerError: Error {
    case expectationFailed(ZincCharacter, ZincCharacter)
    case expectingTimezone
    case invalidEmptySymbol
    case invalidEscapeSequence(ZincCharacter)
    case invalidHex(String)
    case invalidNumberLiteral(String)
    case invalidUnicodeEscape(String)
    case multiLineCommentNotClosed
    case unexpectedEndOfFile
    case unexpectedEndOfStr
    case unexpectedEndOfUri
    case unexpectedSymbol(ZincCharacter)
}
