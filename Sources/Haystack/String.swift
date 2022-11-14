import Foundation

extension String: Val {
    public static var valType: ValType { .Str }
    
    public func toZinc() -> String {
        let zinc = self.withZincUnicodeEscaping()
        return "\"\(zinc)\""
    }
    
    func withZincUnicodeEscaping() -> String {
        var zinc = ""
        for c in self.unicodeScalars {
            if c < " " {
                switch c {
                case "\n": zinc.append(#"\n"#)
                case "\r": zinc.append(#"\r"#)
                case "\t": zinc.append(#"\t"#)
                case "\"": zinc.append(#"""#)
                case "\\": zinc.append(#"\\"#)
                default: zinc.append(c.haystackUnicodeFormat())
                }
            } else {
                if c.isASCII {
                    zinc.append(c.escaped(asASCII: true))
                } else {
                    zinc.append(c.haystackUnicodeFormat())
                }
            }
        }
        return zinc
    }
}

private extension Unicode.Scalar {
    func haystackUnicodeFormat() -> String {
        return "\\u\(String(format:"%04x", self.value))"
    }
}
