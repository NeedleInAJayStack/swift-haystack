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
        // empty grid handler
        if colNames == ["empty"] {
            return Grid(
                meta: Dict(meta),
                cols: [],
                rows: []
            )
        }
        
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
    /// Append a new column to the grid.
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
        
        rows = rows.map { row in
            var newRow = row
            newRow[name] = Null.val
            return newRow
        }
        
        return self
    }
    
    @discardableResult
    /// Append a list of new columns to the grid.
    /// - Parameters:
    ///   - names: The names of the new columns
    /// - Returns: This instance for chaining
    public func addCols(names: [String]) throws -> Self {
        for name in names {
            try self.addCol(name: name)
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
    /// Append a new row to the grid. Newly seen columns are added automatically with no metadata, although column ordering is not guaranteed.
    /// - Parameter vals: The values of the row, in the same order as the columns.
    /// - Returns: This instance for chaining
    public func addRow(_ row: [String: any Val]) throws -> Self {
        for (colName, _) in row {
            if !colNames.contains(colName) {
                try self.addCol(name: colName)
            }
        }
        rows.append(row)
        
        return self
    }
    
    @discardableResult
    /// Append a new row to the grid.
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
    
    @discardableResult
    /// Append new rows to the grid.
    /// - Parameter vals: The values of the rows, in the same order as the columns.
    /// - Returns: This instance for chaining
    public func addRows(_ rows: [[any Val]]) throws -> Self {
        for row in rows {
            try self.addRow(row)
        }
        return self
    }
    
    @discardableResult
    /// Append a new row to the grid. Newly seen columns are added automatically with no metadata, although column ordering is not guaranteed.
    /// - Parameter vals: The values of the row, in the same order as the columns.
    /// - Returns: This instance for chaining
    public func addRow(_ dict: Dict) throws -> Self {
        try self.addRow(dict.elements)
        return self
    }
    
    @discardableResult
    /// Append a new row to the grid. Newly seen columns are added automatically with no metadata, although column ordering is not guaranteed.
    /// - Parameter vals: The values of the row, in the same order as the columns.
    /// - Returns: This instance for chaining
    public func addRows(_ dicts: [Dict]) throws -> Self {
        for dict in dicts {
            try self.addRow(dict)
        }
        return self
    }
}

enum GridBuilderError: Error {
    case cannotAddColAfterRows
    case colAlreadyDefined(name: String)
    case colNotDefined(name: String)
    case valCountDoesntMatchColCount
}
