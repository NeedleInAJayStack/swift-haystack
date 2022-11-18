import Foundation

/// Fluent builder used to create immutable Grid objects.
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
    
    /// Construct a grid from the assets of this instance
    /// - Returns: The resulting grid
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
    /// Set grid-level metadata.
    /// - Parameter keysAndVals: The key and value pairs to set on the grid metadata.`remove` removes the key entry.
    /// - Returns: This instance for chaining
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
    /// Append a new column to the grid. New columns may not be added if the builder contains rows.
    /// - Parameters:
    ///   - name: The name of the new column
    ///   - meta: Column-level metadata for the new column
    /// - Returns: This instance for chaining
    public func addCol(name: String, meta: [String: any Val]? = nil) throws -> Self {
        guard rows.count == 0 else {
            throw GridBuilderError.cannotAddColAfterRows
        }
        
        guard !colNames.contains(name) else {
            throw GridBuilderError.colAlreadyDefined(name: name)
        }
        colNames.append(name)
        if let meta = meta {
            colMeta[name] = meta
        }
        
        return self
    }
    
    @discardableResult
    /// Set column-level metadata for an existing column
    /// - Parameters:
    ///   - name: The name of the existing column
    ///   - keysAndVals: The key-value pairs to set on the column-level metadata. `remove` removes the key entry.
    /// - Returns: This instance for chaining
    public func setColMeta(name: String, _ keysAndVals: [String: any Val]) throws -> Self {
        guard var meta = colMeta[name] else {
            throw GridBuilderError.colNotDefined(name: name)
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
    /// Append a new row to the grid. No new columns may be defined on the builder after calling this function.
    /// - Parameter vals: The values of the row, in the same order as the columns.
    /// - Returns: This instance for chaining
    public func addRow(_ vals: [any Val]) throws -> Self {
        guard vals.count == colNames.count else {
            throw GridBuilderError.valCountDoesntMatchColCount
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
    case cannotAddColAfterRows
    case colAlreadyDefined(name: String)
    case colNotDefined(name: String)
    case valCountDoesntMatchColCount
}
