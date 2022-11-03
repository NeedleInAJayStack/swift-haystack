import Foundation

struct List: Val {
    public static var valType: ValType { .List }
    
    var elements: [any Val]
    
    public init(_ elements: [any Val]) {
        self.elements = elements
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
        
        elements = []
        containerLoop: while !container.isAtEnd {
            typeLoop: for type in ValType.allCases {
                if let val = try? container.decode(type.type) {
                    elements.append(val)
                    break typeLoop
                }
            }
        }
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
    static func == (lhs: List, rhs: List) -> Bool {
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
    func hash(into hasher: inout Hasher) {
        for element in elements {
            hasher.combine(element)
        }
    }
}

// List + ExpressibleByDictionaryLiteral
extension List: ExpressibleByArrayLiteral {
    init(arrayLiteral: any Val...) {
        self.elements = arrayLiteral
    }
}
