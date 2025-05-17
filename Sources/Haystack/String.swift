import Foundation

/// Str is a sequence of zero or more Unicode characters. Implementations must fully support at least the
/// Basic Multilingual Plane (plane 0), which covers all the 16-bit code points. All text formats must be encoded
/// using UTF-8 unless explicitly specified otherwise (such as via a charset parameter in an HTTP Content-Type).
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#str)
extension String: Val {
    public static var valType: ValType { .Str }

    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        let zinc = withZincUnicodeEscaping()
        return "\"\(zinc)\""
    }

    func withZincUnicodeEscaping() -> String {
        var zinc = ""
        for c in unicodeScalars {
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
        return "\\u\(String(format: "%04x", value))"
    }
}
