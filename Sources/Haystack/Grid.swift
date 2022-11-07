import Foundation

public struct Grid: Val {
    public static var valType: ValType { .Grid }
    
    public let meta: Dict
    public let cols: [Col]
    public let rows: [Dict]
    
    init(meta: Dict, cols: [Col], rows: [Dict]) {
        self.meta = meta
        self.cols = cols
        self.rows = rows
    }
    
    public func toZinc() -> String {
        var zinc = #"ver:"3.0""#
        if meta.elements.count > 0 {
            zinc += " \(meta.toZinc(withBraces: false))"
        }
        zinc += "\n"
        
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
        
        return zinc
    }
}

/// See https://project-haystack.org/doc/docHaystack/Json#grid
extension Grid {
    static let kindValue = "grid"
    
    enum CodingKeys: CodingKey {
        case _kind
        case meta
        case cols
        case rows
    }
    
    public init(from decoder: Decoder) throws {
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
            
            self.meta = try container.decode(Dict.self, forKey: .meta)
            self.cols = try container.decode([Col].self, forKey: .cols)
            self.rows = try container.decode([Dict].self, forKey: .rows)
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Self.CodingKeys)
        try container.encode(Self.kindValue, forKey: ._kind)
        try container.encode(meta, forKey: .meta)
        try container.encode(cols, forKey: .cols)
        try container.encode(rows, forKey: .rows)
    }
}

// Dict + Equatable
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

// Dict + Hashable
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
