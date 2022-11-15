import Foundation

/// List is a collection data type. Lists are ordered sequences and may contain any other valid
/// Haystack data types.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#list)
public struct List: Val {
    public static var valType: ValType { .List }
    
    public let elements: [any Val]
    
    public init(_ elements: [any Val]) {
        self.elements = elements
    }
    
    public func toZinc() -> String {
        let zincElements = elements.map { $0.toZinc() }
        return "[\(zincElements.joined(separator:", "))]"
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#list
extension List: Encodable {
    public init(from decoder: Decoder) throws {
        guard var container = try? decoder.unkeyedContainer() else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "List representation must be an array"
                )
            )
        }
        
        var elements = [any Val]()
        containerLoop: while !container.isAtEnd {
            typeLoop: for type in ValType.allCases {
                if let val = try? container.decode(type.type) {
                    elements.append(val)
                    break typeLoop
                }
            }
        }
        self.elements = elements
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for element in elements {
            try container.encode(element)
        }
    }
}

// List + Equatable
extension List {
    public static func == (lhs: List, rhs: List) -> Bool {
        guard lhs.elements.count == rhs.elements.count else {
            return false
        }
        
        for (lhsElement, rhsElement) in zip(lhs.elements, rhs.elements) {
            guard lhsElement.equals(rhsElement) else {
                return false
            }
        }
        
        return true
    }
}

// List + Hashable
extension List {
    public func hash(into hasher: inout Hasher) {
        for element in elements {
            hasher.combine(element)
        }
    }
}

// List + ExpressibleByDictionaryLiteral
extension List: ExpressibleByArrayLiteral {
    public init(arrayLiteral: any Val...) {
        self.elements = arrayLiteral
    }
}
