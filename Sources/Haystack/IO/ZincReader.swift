import Foundation

public class ZincReader {
    let tokenizer: ZincTokenizer
    
    var cur: ZincToken = .eof
    var curVal: any Val = null
    var curLine: Int = 0
    var peek: ZincToken = .eof
    var peekVal: any Val = null
    var peekLine: Int = 0
    
    public init(_ data: Data) throws {
        tokenizer = try ZincTokenizer(data)
        try consume()
        try consume()
    }
    
    public convenience init(_ string: String) throws {
        guard let data = string.data(using: .ascii) else {
            throw ZincReaderError.InputIsNotUtf8
        }
        try self.init(data)
    }
    
    public func readVal() throws -> any Val {
        var val: any Val = null
        if cur == .id, curVal.equals("ver") {
            val = try parseGrid()
        } else {
            val = try parseVal()
        }
        try verify(.eof)
        return val
    }
    
    public func readGrid() throws -> Grid {
        guard let grid = try readVal() as? Grid else {
            throw ZincReaderError.InputIsNotGrid
        }
        return grid
    }
    
    private func parseVal() throws -> any Val {
        if cur == .id {
            guard let id = curVal as? String else {
                throw ZincReaderError.IdValueIsNotString(curVal)
            }
            try consume(.id)
            
            // check for Coord or XStr
            if cur == .lparen {
                if peek == .num {
                    return try parseCoord(id)
                } else {
                    return try parseXStr(id)
                }
            }
            
            switch id {
            case "T": return true
            case "F": return false
            case "N": return null
            case "M": return marker
            case "R": return remove
            case "NA": return na
            case "NaN": return Number(val: .nan)
            case "INF": return Number(val: .infinity)
            default:
                throw ZincReaderError.UnexpectedId(id)
            }
        }
        
        if cur.isLiteral {
            return try parseLiteral()
        }
        
        // -INF
        if cur == .minus, peek == .id, peekVal.equals("INF") {
            try consume(.minus)
            try consume(.id)
            return Number(val: -1.0 * .infinity)
        }
        
        if cur == .lbracket {
            return try parseList()
        }
        if cur == .lbrace {
            return try parseDict()
        }
        if cur == .lt2 {
            return try parseGrid()
        }
        
        throw ZincReaderError.UnexpectedToken(cur)
    }
    
    private func parseCoord(_ id: String) throws -> Coord {
        guard id == "C" else {
            throw ZincReaderError.InvalidCoord
        }
        try consume(.lparen)
        let latitude = try consumeNumber()
        try consume(.comma)
        let longitude = try consumeNumber()
        try consume(.rparen)
        return Coord(lat: latitude.val, lng: longitude.val)
    }
    
    private func parseXStr(_ id: String) throws -> XStr {
        guard (id.first?.isLowercase ?? false) else {
            throw ZincReaderError.InvalidXStr
        }
        try consume(.lparen)
        let val = try consumeString()
        try consume(.rparen)
        return XStr(type: id, val: val)
    }
    
    private func parseLiteral() throws -> any Val {
        var val = self.curVal
        if cur == .ref, peek == .str {
            guard let refVal = curVal as? String, let dis = peekVal as? String else {
                throw ZincReaderError.InvalidRef
            }
            val = Ref(val: refVal, dis: dis)
            try consume(.ref)
        }
        try consume()
        return val
    }
    
    private func parseList() throws -> List {
        var elements = [any Val]()
        while cur != .rbracket, cur != .eof {
            try elements.append(parseVal())
            guard cur == .comma else {
                break
            }
            try consume(.comma)
        }
        try consume(.rbracket)
        return List(elements)
    }
    
    private func parseDict() throws -> Dict {
        var elements = [String: any Val]()
        let hasBraces = cur == .lbrace
        if hasBraces {
            try consume(.lbrace)
        }
        while cur == .id {
            let id = try consumeTagName()
            var val: any Val = marker
            if cur == .colon {
                try consume(.colon)
                val = try parseVal()
            }
            elements[id] = val
        }
        if hasBraces {
            try consume(.rbrace)
        }
        
        return Dict(elements)
    }
    
    private func parseGrid() throws -> Grid {
        let isNested = cur == .lt2
        if isNested {
            try consume(.lt2)
            if cur == .nl {
                try consume(.nl)
            }
        }
        
        // Check version
        guard cur == .id, curVal.equals("ver") else {
            throw ZincReaderError.GridDoesNotBeginWithVersion(curVal)
        }
        try consume()
        try consume(.colon)
        let version = try consumeString()
        guard version == "3.0" else {
            throw ZincReaderError.UnsupportedZincVersion(version)
        }
        
        // Metadata
        let builder = GridBuilder()
        if cur == .id {
            try builder.setMeta(parseDict().elements)
        }
        try consume(.nl)
        
        // Columns
        var numCols = 0
        while cur == .id {
            numCols += 1
            let name = try consumeTagName()
            var colMeta: [String: any Val]? = nil
            if cur == .id {
                colMeta = try parseDict().elements
            }
            try builder.addCol(name: name, meta: colMeta)
            
            guard cur == .comma else {
                break
            }
            try consume(.comma)
        }
        guard numCols > 0 else {
            throw ZincReaderError.GridHasNoColumns
        }
        try consume(.nl)
        
        // Rows
        while true {
            if cur == .nl || cur == .eof || (isNested && cur == .gt2) {
                break
            }
            
            var cells = [any Val]()
            for i in 0 ..< numCols {
                if cur == .comma || cur == .nl || cur == .eof {
                    cells.append(null)
                } else {
                    try cells.append(parseVal())
                }
                if i+1 < numCols {
                    try consume(.comma)
                }
            }
            try builder.addRow(cells)
            
            if cur == .eof || (isNested && cur == .gt2) {
                break
            }
            try consume(.nl)
        }
        
        if cur == .nl {
            try consume(.nl)
        }
        if isNested {
            try consume(.gt2)
        }
        return builder.toGrid()
    }
    
    // MARK: Token Reads
    
    private func consumeTagName() throws -> String {
        try verify(.id)
        guard let id = curVal as? String else {
            throw ZincReaderError.IdValueIsNotString(curVal)
        }
        guard (id.first?.isLowercase ?? false) else {
            throw ZincReaderError.InvalidTagName
        }
        try consume(.id)
        return id
    }
    
    private func consumeNumber() throws -> Number {
        try verify(.num)
        guard let number = curVal as? Number else {
            throw ZincReaderError.NumValueIsNotNumber(curVal)
        }
        try consume(.num)
        return number
    }
    
    private func consumeString() throws -> String {
        try verify(.str)
        guard let number = curVal as? String else {
            throw ZincReaderError.StrValueIsNotString(curVal)
        }
        try consume(.str)
        return number
    }
    
    private func consume(_ expected: ZincToken? = nil) throws {
        if let expected = expected {
            try verify(expected)
        }
        cur = peek;
        curVal = peekVal;
        curLine = peekLine;

        peek = try tokenizer.next();
        peekVal = tokenizer.val;
        peekLine = tokenizer.line;
    }
    
    private func verify(_ expected: ZincToken) throws {
        if cur != expected {
            throw ZincReaderError.ExpectedToken(expected, not: cur)
        }
    }
}

enum ZincReaderError: Error {
    case ExpectedToken(ZincToken, not: ZincToken)
    case GridDoesNotBeginWithVersion(any Val)
    case GridHasNoColumns
    case IdValueIsNotString(any Val)
    case InputIsNotUtf8
    case InvalidCoord
    case InvalidRef
    case InvalidTagName
    case InvalidXStr
    case NumValueIsNotNumber(any Val)
    case StrValueIsNotString(any Val)
    case UnexpectedId(String)
    case UnexpectedToken(ZincToken)
    case InputIsNotGrid
    case UnsupportedZincVersion(String)
}
