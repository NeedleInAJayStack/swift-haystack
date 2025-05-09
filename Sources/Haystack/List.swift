import Foundation

/// List is a collection data type. Lists are ordered sequences and may contain any other valid
/// Haystack data types.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#list)
public struct List: Val {
    public static var valType: ValType { .List }
    
    public private(set) var elements: [any Val]
    
    public init(_ elements: [any Val]) {
        self.elements = elements
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        let zincElements = elements.map { $0.toZinc() }
        return "[\(zincElements.joined(separator:", "))]"
    }
    
    public func toSwiftArray() -> [any Val] {
        return elements
    }
}

// List + Codable
extension List {
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#list)
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
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#list)
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

// List + Collection
extension List: Collection {
    public var startIndex: Int {
        elements.startIndex
    }
    
    public var endIndex: Int {
        elements.endIndex
    }
    
    public subscript(position: Int) -> any Val {
        return elements[position]
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }
}

extension List: ExpressibleByArrayLiteral {
    /// Creates an instance initialized with the given elements.
    public init(arrayLiteral: any Val...) {
        self.elements = arrayLiteral
    }
}
