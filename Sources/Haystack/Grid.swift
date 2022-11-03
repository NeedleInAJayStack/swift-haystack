import Foundation

struct Grid: Val {
    public var valType: ValType { .Grid }
    
    let meta: Dict
    let cols: [Col]
    let rows: [Dict]
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
    static func == (lhs: Grid, rhs: Grid) -> Bool {
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(meta)
        for col in cols {
            hasher.combine(col.name)
            hasher.combine(col.meta)
        }
        hasher.combine(rows)
    }
}

struct Col: Codable {
    let name: String
    let meta: Dict?
    
    init(name: String, meta: Dict? = nil) {
        self.name = name
        self.meta = meta
    }
}
