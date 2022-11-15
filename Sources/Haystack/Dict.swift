import Foundation

/// Dict (or dictionary) is the primary collection data type in Haystack. Dicts are an unordered collection of
/// name/value pairs that we call *tags*. The name keys of a dict are restricted to ASCII letters, digits and
/// underbar as discussed in the
/// [names](https://project-haystack.org/doc/docHaystack/Kinds#names)
/// section. The values may be be any other valid Haystack data type.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#dict)
public struct Dict: Val {
    public static var valType: ValType { .Dict }
    
    public static func empty() -> Dict {
        return Dict([:])
    }
    
    public let elements: [String: any Val]
    
    public init(_ elements: [String: any Val]) {
        self.elements = elements
    }
    
    public func toZinc() -> String {
        return toZinc(withBraces: true)
    }
    
    func toZinc(withBraces: Bool) -> String {
        let zincElements = elements.keys.sorted().map { key in
            "\(key):\(elements[key]!.toZinc())" // unwrap is safe due to immutability
        }
        let zinc = zincElements.joined(separator: " ")
        
        if withBraces {
            return "{\(zinc)}"
        } else {
            return zinc
        }
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#dict
extension Dict {
    static let kindValue = "dateTime"
    
    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: DictCodingKey.self) else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Dict representation must be an object"
                )
            )
        }
        
        var elements = [String: any Val]()
        containerLoop: for key in container.allKeys {
            if key.stringValue == "_kind" {
                guard
                    let value = try? container.decode(String.self, forKey: key),
                    value == Self.kindValue
                else {
                    throw DecodingError.typeMismatch(
                        Self.self,
                        .init(
                            codingPath: [key],
                            debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                        )
                    )
                }
            } else {
                typeLoop: for type in ValType.allCases {
                    if let val = try? container.decode(type.type, forKey: key) {
                        elements[key.stringValue] = val
                        break typeLoop
                    }
                }
            }
        }
        self.elements = elements
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DictCodingKey.self)
        for (key, value) in elements {
            guard let codingKey = DictCodingKey(stringValue: key) else {
                throw EncodingError.invalidValue(
                    self,
                    .init(
                        codingPath: [],
                        debugDescription: "CodingKey not found: \(key)"
                    )
                )
            }
            
            try container.encode(value, forKey: codingKey)
        }
    }
    
    private struct DictCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = Int(stringValue)
        }

        init?(intValue: Int) {
            stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}

// Dict + Equatable
extension Dict {
    public static func == (lhs: Dict, rhs: Dict) -> Bool {
        guard lhs.elements.count == rhs.elements.count else {
            return false
        }
        
        guard lhs.elements.keys == rhs.elements.keys else {
            return false
        }
        
        for key in lhs.elements.keys {
            guard
                let lhsValue = lhs.elements[key],
                let rhsValue = rhs.elements[key]
            else {
                return false
            }
            
            guard lhsValue.equals(rhsValue) else {
                return false
            }
        }
        
        return true
    }
}

// Dict + Hashable
extension Dict {
    public func hash(into hasher: inout Hasher) {
        for (key, value) in elements {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

// Dict + ExpressibleByDictionaryLiteral
extension Dict: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elementLiterals: (String, any Val)...) {
        var elements = [String: any Val](minimumCapacity: elementLiterals.count)
        for (key, value) in elementLiterals {
            elements[key] = value
        }
        self.elements = elements
    }
}
