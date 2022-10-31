import Foundation

extension String: Val {
    public var valType: ValType { .Str }
    
    public func toZinc() -> String {
        var string = ""
        for c in self.unicodeScalars {
            if c < " " {
                switch c {
                case "\n": string.append(#"\n"#)
                case "\r": string.append(#"\r"#)
                case "\t": string.append(#"\t"#)
                case "\"": string.append(#"""#)
                case "\\": string.append(#"\\"#)
                default: string.append(c.haystackUnicodeFormat())
                }
            } else {
                if c.isASCII {
                    string.append(c.escaped(asASCII: true))
                } else {
                    string.append(c.haystackUnicodeFormat())
                }
            }
        }
        return "\"\(string)\""
    }
}

private extension Unicode.Scalar {
    func haystackUnicodeFormat() -> String {
        return "\\u\(String(format:"%04x", self.value))"
    }
}
