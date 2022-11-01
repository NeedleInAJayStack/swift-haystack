import Foundation

struct Dict: Val {
    public var valType: ValType { .Dict }
    
    var elements: [String: any Val]
    
    public init(_ elements: [String: any Val]) {
        self.elements = elements
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
        
        elements = [:]
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
    static func == (lhs: Dict, rhs: Dict) -> Bool {
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
    func hash(into hasher: inout Hasher) {
        for (key, value) in elements {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

// Dict + ExpressibleByDictionaryLiteral
extension Dict: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, any Val)...) {
        self.elements = [String: any Val](minimumCapacity: elements.count)
        for (key, value) in elements {
            self.elements[key] = value
        }
    }
}
