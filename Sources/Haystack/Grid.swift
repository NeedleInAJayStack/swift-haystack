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
    
    public let meta: Dict
    public let cols: [Col]
    public let rows: [Dict]
    
    // Collection conformance
    public var startIndex: Int
    public var endIndex: Int
    
    init(meta: Dict, cols: [Col], rows: [Dict]) {
        self.meta = meta
        self.cols = cols
        self.rows = rows
        
        self.startIndex = 0
        self.endIndex = rows.count - 1
    }
    
    /// Converts to Zinc formatted string.
    /// See [Zinc Literals](https://project-haystack.org/doc/docHaystack/Zinc#literals)
    public func toZinc() -> String {
        // Ensure `ver` is listed first in meta
        let ver = meta.elements["ver"] ?? "3.0"
        var zinc = "ver:\(ver.toZinc())"
        
        var metaWithoutVer = meta.elements
        metaWithoutVer["ver"] = nil
        if metaWithoutVer.count > 0 {
            zinc += " \(Dict(metaWithoutVer).toZinc(withBraces: false))"
        }
        zinc += "\n"
        
        if cols.isEmpty {
            zinc += "empty\n"
        } else {
            let zincCols = cols.map { col in
                var colZinc = col.name
                if let colMeta = col.meta, colMeta.elements.count > 0 {
                    colZinc += " \(colMeta.toZinc(withBraces: false))"
                }
                return colZinc
            }
            zinc += zincCols.joined(separator: ", ")
            zinc += "\n"
            
            let zincRows = rows.map { row in
                let rowZincElements = cols.map { col in
                    let element = row.elements[col.name] ?? null
                    return element.toZinc()
                }
                return rowZincElements.joined(separator: ", ")
            }
            zinc += zincRows.joined(separator: "\n")
        }
        
        return zinc
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
        let meta: Dict
        let cols: [Col]
        let rows: [Dict]
        
        if let container = try? decoder.container(keyedBy: Self.CodingKeys) {
            guard try container.decode(String.self, forKey: ._kind) == Self.kindValue else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: [Self.CodingKeys._kind],
                        debugDescription: "Expected `_kind` to have value `\"\(Self.kindValue)\"`"
                    )
                )
            }
            
            meta = try container.decode(Dict.self, forKey: .meta)
            let decodedCols = try container.decode([Col].self, forKey: .cols)
            if decodedCols.map(\.name) == ["empty"] {
                cols = []
                rows = []
            } else {
                cols = decodedCols
                rows = try container.decode([Dict].self, forKey: .rows)
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
        
        self.init(meta: meta, cols: cols, rows: rows)
    }
    
    /// Write to encodable data
    /// See [JSON format](https://project-haystack.org/doc/docHaystack/Json#grid)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(meta, forKey: .meta)
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

public struct Col: Codable {
    let name: String
    let meta: Dict?
    
    public init(name: String, meta: Dict? = nil) {
        self.name = name
        self.meta = meta
    }
}

extension Grid: Collection {
    public subscript(position: Int) -> Dict {
        get {
            rows[position]
        }
    }
    public func index(after i: Int) -> Int {
        return i + 1
    }
}
