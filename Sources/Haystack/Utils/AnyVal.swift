/// This type-erased struct centralizes general operations that may act across different Haystack value types unknown
/// at compile time like equality, decoding, and comparison.
struct AnyVal: Codable, Hashable, Sendable {
    /// The underlying value of the AnyVal, which conforms to the Val protocol.
    let val: any Val

    init(_ val: any Val) {
        self.val = val
    }

    func toZinc() -> String {
        return val.toZinc()
    }
}

// AnyVal + Equatable
extension AnyVal {
    static func == (lhs: AnyVal, rhs: AnyVal) -> Bool {
        return lhs.val.equals(rhs.val)
    }
}

// AnyVal + Codable
extension AnyVal {
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#list)
    init(from decoder: Decoder) throws {
        typeLoop: for type in ValType.allCases {
            if let val = try? type.type.init(from: decoder) {
                self = .init(val)
                return
            }
        }
        throw DecodingError.typeMismatch(
            AnyVal.self,
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "No Val type matched"
            )
        )
    }

    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#list)
    func encode(to encoder: Encoder) throws {
        try val.encode(to: encoder)
    }
}

// AnyVal + Hashable
extension AnyVal {
    func hash(into hasher: inout Hasher) {
        hasher.combine(val)
    }
}
