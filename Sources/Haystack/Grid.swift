import Foundation

/// Grid is a two dimensional tabular data type. Grids are essentially a list of dicts. However, grids may
/// include grid level and column level meta data that is modeled as a dict. Grids are the fundamental
/// unit of data exchange over the
/// [HTTP API](https://project-haystack.org/doc/docHaystack/HttpApi).
///
/// To create a Grid, use a `GridBuilder`.
///
/// [Docs](https://project-haystack.org/doc/docHaystack/Kinds#grid)
public struct Grid: Val {
    public static var valType: ValType { .Grid }
    
    public private(set) var meta: Dict
    public private(set) var cols: [Col]
    public private(set) var rows: [Dict]
    
    init(meta: Dict, cols: [Col], rows: [Dict]) {
        self.meta = meta
        self.cols = cols
        self.rows = rows
    }
    
    /// Create a Grid with no column metadata from a list of Dicts.
    ///
    /// There is no guarantee on the column ordering.
    /// - Parameters:
    ///   - meta: Grid metadata
    ///   - rows: The rows of the grid
    public init(meta: Dict = [:], rowsAndColumns: [Dict]) {
        self.meta = meta
        var colNames = Set<String>()
        for row in rowsAndColumns {
            for (key, _) in row {
                colNames.insert(key)
            }
        }
        self.cols = colNames.map { Col(name: $0) }
        self.rows = rowsAndColumns
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        // Ensure `ver` is listed first in meta
        let ver = meta["ver"] ?? "3.0"
        var zinc = "ver:\(ver.toZinc())"
        
        var metaWithoutVer = meta
        metaWithoutVer["ver"] = nil
        if metaWithoutVer.count > 0 {
            zinc += " \(metaWithoutVer.toZinc(withBraces: false))"
        }
        zinc += "\n"
        
        if cols.isEmpty {
            zinc += "empty\n"
        } else {
            let zincCols = cols.map { col in
                var colZinc = col.name
                if let colMeta = col.meta, colMeta.count > 0 {
                    colZinc += " \(colMeta.toZinc(withBraces: false))"
                }
                return colZinc
            }
            zinc += zincCols.joined(separator: ", ")
            zinc += "\n"
            
            let zincRows = rows.map { row in
                let rowZincElements = cols.map { col in
                    let element = row[col.name] ?? null
                    return element.toZinc()
                }
                return rowZincElements.joined(separator: ", ")
            }
            zinc += zincRows.joined(separator: "\n")
        }
        
        return zinc
    }
    
    /// Returns a grid that is the same as the existing one, but with its columns reordered according to the input names.
    /// - Parameter newOrder: The names of the columns, in the desired order
    /// - Returns: self for chaining
    public mutating func reorderCols(to newOrder: [String]) throws -> Self {
        var newCols: [Col] = []
        for name in newOrder {
            guard let colIndex = cols.firstIndex(where: { $0.name == name }) else {
                throw GridError.columnNotFound(name)
            }
            newCols.append(cols[colIndex])
        }
        self.cols = newCols
        return self
    }
}

// Grid + Codable
extension Grid {
    static let kindValue = "grid"
    
    enum CodingKeys: CodingKey {
        case _kind
        case meta
        case cols
        case rows
    }
    
    /// Read from decodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#grid)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Self.CodingKeys.self) {
            guard try container.decode(String.self, forKey: ._kind) == Self.kindValue else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys._kind],
                        debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                    )
                )
            }
            
            var meta = try container.decode(Dict.self, forKey: .meta)
            meta["ver"] = nil // Remove version
            self.meta = meta
            let cols = try container.decode([Col].self, forKey: .cols)
            if cols.map(\.name) == ["empty"] {
                self.cols = []
                self.rows = []
            } else {
                self.cols = cols
                self.rows = try container.decode([Dict].self, forKey: .rows)
            }
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Grid representation must be an object"
                )
            )
        }
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#grid)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys.self)
        var versionedMeta = meta
        versionedMeta["ver"] = "3.0"
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(versionedMeta, forKey: .meta)
        if cols.isEmpty {
            try container.encode([Col(name: "empty")], forKey: .cols)
            try container.encode([Dict](), forKey: .rows)
        } else {
            try container.encode(cols, forKey: .cols)
            try container.encode(rows, forKey: .rows)
        }
    }
}

// Grid + Equatable
extension Grid {
    public static func == (lhs: Grid, rhs: Grid) -> Bool {
        guard lhs.meta == rhs.meta else {
            return false
        }
        
        guard lhs.cols.count == rhs.cols.count else {
            return false
        }
        for (lhsCol, rhsCol) in zip(lhs.cols, rhs.cols) {
            guard
                lhsCol.name == rhsCol.name &&
                lhsCol.meta == rhsCol.meta
            else {
                return false
            }
        }
        
        guard lhs.rows.count == rhs.rows.count else {
            return false
        }
        for (lhsRow, rhsRow) in zip(lhs.rows, rhs.rows) {
            guard lhsRow == rhsRow else {
                return false
            }
        }
        
        return true
    }
}

// Grid + Hashable
extension Grid {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(meta)
        for col in cols {
            hasher.combine(col.name)
            hasher.combine(col.meta)
        }
        hasher.combine(rows)
    }
}

// Grid + Collection
extension Grid: Collection {
    public var startIndex: Int {
        rows.startIndex
    }
    
    public var endIndex: Int {
        rows.endIndex
    }
    
    public subscript(position: Int) -> Dict {
        return rows[position]
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }
}

extension Grid: ExpressibleByArrayLiteral {
    /// Create a grid from the provided literals. The grid will have no grid or column-level metadata
    public init(arrayLiteral: Dict...) {
        self.init(meta: [:], rowsAndColumns: arrayLiteral)
    }
}

extension Grid: CustomStringConvertible {
    public var description: String {
        return self.toZinc()
    }
}

public struct Col: Codable, Sendable {
    public let name: String
    public let meta: Dict?
    
    public init(name: String, meta: Dict? = nil) {
        self.name = name
        self.meta = meta
    }
}

public enum GridError: Error {
    case columnNotFound(String)
}
