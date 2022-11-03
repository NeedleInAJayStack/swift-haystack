import Foundation

public class GridBuilder {
    var meta: [String: any Val]
    var colNames: [String]
    var colMeta: [String: [String: any Val]]
    var rows: [[String: any Val]]
    
    public init() {
        meta = [:]
        colNames = []
        colMeta = [:]
        rows = []
    }
    
    public func toGrid() -> Grid {
        let cols = colNames.map { colName in
            if let meta = colMeta[colName] {
                return Col(name: colName, meta: Dict(meta))
            } else {
                return Col(name: colName)
            }
        }
        
        return Grid(
            meta: Dict(meta),
            cols: cols,
            rows: rows.map { row in
                Dict(row)
            }
        )
    }
    
    @discardableResult
    public func setMeta(_ keysAndVals: [String: any Val]) -> Self {
        for (key, val) in keysAndVals {
            if val is Remove {
                meta[key] = nil
            } else {
                meta[key] = val
            }
        }
        return self
    }
    
    @discardableResult
    public func addCol(name: String, meta: [String: any Val]? = nil) throws -> Self {
        guard rows.count == 0 else {
            throw GridBuilderError.CannotAddColAfterRows
        }
        
        guard !colNames.contains(name) else {
            throw GridBuilderError.ColAlreadyDefined(name: name)
        }
        colNames.append(name)
        if let meta = meta {
            colMeta[name] = meta
        }
        
        return self
    }
    
    @discardableResult
    public func setColMeta(name: String, _ keysAndVals: [String: any Val]) throws -> Self {
        guard var meta = colMeta[name] else {
            throw GridBuilderError.ColNotDefined(name: name)
        }
        for (key, val) in keysAndVals {
            if val is Remove {
                meta[key] = nil
            } else {
                meta[key] = val
            }
        }
        colMeta[name] = meta
        return self
    }
    
    @discardableResult
    public func addRow(_ vals: [any Val]) throws -> Self {
        guard vals.count == colNames.count else {
            throw GridBuilderError.ValCountDoesntMatchColCount
        }
        
        var row = [String: any Val]()
        for (key, val) in zip(colNames, vals) {
            row[key] = val
        }
        rows.append(row)
        return self
    }
}

enum GridBuilderError: Error {
    case CannotAddColAfterRows
    case ColAlreadyDefined(name: String)
    case ColNotDefined(name: String)
    case ValCountDoesntMatchColCount
}
