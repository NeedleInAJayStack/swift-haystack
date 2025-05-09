
/**
 * Filter models a parsed tag query string.
 *
 * @see <a href='http://project-haystack.org/doc/Filters'>Project Haystack</a>
 */
public protocol Filter: Hashable, CustomStringConvertible {
    /* Return if given tags entity matches this query. */
    func include(dict: Dict, pather: Pather?) throws -> Bool
}

public extension Filter {
    /** Hash code is based on string encoding */
    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    /** Equality is based on string encoding */
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.description == rhs.description
    }

    /// Existential comparison. This is required because Swift equality requires comparing concrete types.
    /// Will only return true if filter types and input strings match.
    func equals(_ that: any Filter) -> Bool {
        return type(of: self) == type(of: that) && description == that.description
    }

    /**
     * Return a query which is the logical-and of this and that query.
     */
    func and(_ that: any Filter) -> any Filter {
        return And(a: self, b: that)
    }

    /**
     * Return a query which is the logical-or of this and that query.
     */
    func or(_ that: any Filter) -> any Filter {
        return Or(a: self, b: that)
    }
}

// Static method container for constructing concrete filters.
public enum FilterFactory {
    /// Decode a string into a Filter
    public static func make(_ s: String) throws -> any Filter {
        return try FilterParser(in: s).parse()
    }

    /**
     * Match records which have the specified tag path defined.
     */
    public static func has(_ path: String) throws -> any Filter {
        return try Has(path: Path.make(path: path))
    }

    /**
     * Match records which do not define the specified tag path.
     */
    public static func missing(_ path: String) throws -> any Filter {
        return try Missing(path: Path.make(path: path))
    }

    /**
     * Match records which have a tag are equal to the specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func eq(_ path: String, _ val: any Val) throws -> any Filter {
        return try Eq(val: val, path: Path.make(path: path))
    }

    /**
     * Match records which have a tag not equal to the specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func ne(_ path: String, _ val: any Val) throws -> any Filter {
        return try Ne(val: val, path: Path.make(path: path))
    }

    /**
     * Match records which have tags less than the specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func lt(_ path: String, _ val: any Val) throws -> any Filter {
        return try Lt(val: val, path: Path.make(path: path))
    }

    /**
     * Match records which have tags less than or equals to specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func le(_ path: String, _ val: any Val) throws -> any Filter {
        return try Le(val: val, path: Path.make(path: path))
    }

    /**
     * Match records which have tags greater than specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func gt(_ path: String, _ val: any Val) throws -> any Filter {
        return try Gt(val: val, path: Path.make(path: path))
    }

    /**
     * Match records which have tags greater than or equal to specified value.
     * If the path is not defined then it is unmatched.
     */
    public static func ge(_ path: String, _ val: any Val) throws -> any Filter {
        return try Ge(val: val, path: Path.make(path: path))
    }
}

/** Pather is a callback interface used to resolve query paths.
 *
 * Given a Ref string identifier, resolve to an entity's
 * Dict respresentation or ref is not found return null.
 */
public typealias Pather = (String) -> Dict?

protocol PathFilter: Filter {
    var path: Path { get }
    func doInclude(val: any Val) -> Bool
}

/// This is used to from PathFilter `include` methods to wrap the `doInclude` definition.
///
/// It's done this way because concrete types don't inherit conformance defined on the protocol, and classes don't support abstract methods.
func pathFilterInclude(pathFilter: any PathFilter, dict: Dict, pather: Pather?) throws -> Bool {
    var val = try dict.get(pathFilter.path[0]) ?? null
    if pathFilter.path.count != 1 {
        if let pather = pather {
            var nt: Dict? = dict
            for i in 1 ..< pathFilter.path.count {
                if let val = val as? Dict {
                    nt = val
                } else if let val = val as? Ref {
                    nt = pather(val.val)
                } else {
                    val = null
                    break
                }
                val = try nt?.get(pathFilter.path[i]) ?? null
            }
        } else {
            val = null
        }
    }
    return pathFilter.doInclude(val: val)
}

class Has: PathFilter {
    var path: Path

    init(path: Path) {
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func doInclude(val: any Val) -> Bool {
        return !(val is Null)
    }

    var description: String {
        return path.description
    }
}

class Missing: PathFilter {
    var path: Path

    init(path: Path) {
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func doInclude(val: any Val) -> Bool {
        return val is Null
    }

    var description: String {
        return "not " + path.description
    }
}

protocol CmpFilter: PathFilter {
    var val: any Val { get }
    func cmpStr() -> String
}

extension CmpFilter {
    var description: String {
        var s = ""
        s.append(path.description)
        s.append(cmpStr())
        s.append(val.toZinc())
        return s
    }

    func sameType(val: any Val) -> Bool {
        return !(val is Null) && type(of: val).valType == type(of: self.val).valType
    }
}

class Eq: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return "=="
    }

    func doInclude(val: any Val) -> Bool {
        return !(val is Null) && val.equals(self.val)
    }
}

class Ne: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return "!="
    }

    func doInclude(val: any Val) -> Bool {
        return !(val is Null) && !val.equals(self.val)
    }
}

class Lt: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return "<"
    }

    func doInclude(val: any Val) -> Bool {
        return sameType(val: val) && val.toZinc() < self.val.toZinc()
    }
}

class Le: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return "<="
    }

    func doInclude(val: any Val) -> Bool {
        return sameType(val: val) && val.toZinc() <= self.val.toZinc()
    }
}

class Gt: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return ">"
    }

    func doInclude(val: any Val) -> Bool {
        return sameType(val: val) && val.toZinc() > self.val.toZinc()
    }
}

class Ge: CmpFilter {
    var val: any Val
    var path: Path

    init(val: any Val, path: Path) {
        self.val = val
        self.path = path
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try pathFilterInclude(pathFilter: self, dict: dict, pather: pather)
    }

    func cmpStr() -> String {
        return ">="
    }

    func doInclude(val: any Val) -> Bool {
        return sameType(val: val) && val.toZinc() >= self.val.toZinc()
    }
}

protocol CompoundFilter: Filter {
    var a: any Filter { get }
    var b: any Filter { get }

    func keyword() -> String
}

extension CompoundFilter {
    var description: String {
        var s = ""
        if a is any CompoundFilter {
            s.append("(")
            s.append(a.description)
            s.append(")")
        } else {
            s.append(a.description)
        }
        s.append(" ")
        s.append(keyword())
        s.append(" ")
        if b is any CompoundFilter {
            s.append("(")
            s.append(b.description)
            s.append(")")
        } else {
            s.append(b.description)
        }
        return s
    }
}

class And: CompoundFilter {
    let a: any Filter
    let b: any Filter

    init(a: any Filter, b: any Filter) {
        self.a = a
        self.b = b
    }

    func keyword() -> String {
        return "and"
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try a.include(dict: dict, pather: pather) && b.include(dict: dict, pather: pather)
    }
}

class Or: CompoundFilter {
    let a: any Filter
    let b: any Filter

    init(a: any Filter, b: any Filter) {
        self.a = a
        self.b = b
    }

    func keyword() -> String {
        return "or"
    }

    func include(dict: Dict, pather: Pather?) throws -> Bool {
        return try a.include(dict: dict, pather: pather) || b.include(dict: dict, pather: pather)
    }
}

/// Path is a simple name or a complex path using the "->" separator
public struct Path: Hashable, Equatable {
    let string: String
    let names: [String]

    init(_ s: String) {
        string = s
        names = [s]
    }

    init(s: String, n: [String]) {
        string = s
        names = n
    }

    /** Construct a new Path from string or throw ParseException */
    public static func make(path: String) throws -> Path {
        var dash = path.firstIndex(of: "-")

        // parse
        var s = path.startIndex
        var acc = [Substring]()
        var first = true
        while true {
            guard let thisDash = dash else {
                if first {
                    return Path(s: path, n: [path])
                } else {
                    let rest = path[s ..< path.endIndex]
                    if rest.count == 0 {
                        throw ParseError.path("Path: " + path)
                    }
                    acc.append(rest)
                    break
                }
            }
            let n = path[s ..< thisDash]
            if n.count == 0 {
                throw ParseError.path("Path: " + path)
            }
            acc.append(n)
            if path[path.index(after: thisDash)] != ">" {
                throw ParseError.path("Path: " + path)
            }
            s = path.index(after: thisDash)
            s = path.index(after: s)
            dash = path[s ..< path.endIndex].firstIndex(of: "-")
            first = false
        }
        return Path(s: path, n: acc.map { String($0) })
    }
}

extension Path: CustomStringConvertible {
    public var description: String {
        return string
    }
}

extension Path: Collection {
    public typealias Index = Int

    public var startIndex: Int {
        return names.startIndex
    }

    public var endIndex: Int {
        return names.endIndex
    }

    public subscript(position: Int) -> String {
        return names[position]
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }
}

enum ParseError: Error {
    case filter(String)
    case path(String)
}

public class FilterParser {
    private let tokenizer: ZincTokenizer
    private var cur: ZincToken?
    private var curVal: any Val
    private var peek: ZincToken?
    private var peekVal: any Val

    public init(in: String) throws {
        tokenizer = try ZincTokenizer(`in`)
        curVal = null
        peekVal = null
        try consume()
        try consume()
    }

    public func parse() throws -> any Filter {
        let f = try condOr()
        try verify(expected: ZincToken.eof)
        return f
    }

    private func condOr() throws -> any Filter {
        let lhs = try condAnd()
        if !isKeyword("or") {
            return lhs
        }
        try consume()
        return try lhs.or(condOr())
    }

    private func condAnd() throws -> any Filter {
        let lhs = try term()
        if !isKeyword("and") {
            return lhs
        }
        try consume()
        return try lhs.and(condAnd())
    }

    private func term() throws -> any Filter {
        if cur == ZincToken.lparen {
            try consume()
            let f = try condOr()
            try consume(expected: ZincToken.rparen)
            return f
        }

        if isKeyword("not"), peek == ZincToken.id {
            try consume()
            return try Missing(path: path())
        }

        let p = try path()
        if cur == ZincToken.eq {
            try consume()
            return try Eq(val: val(), path: p)
        }
        if cur == ZincToken.notEq {
            try consume()
            return try Ne(val: val(), path: p)
        }
        if cur == ZincToken.lt {
            try consume()
            return try Lt(val: val(), path: p)
        }
        if cur == ZincToken.ltEq {
            try consume()
            return try Le(val: val(), path: p)
        }
        if cur == ZincToken.gt {
            try consume()
            return try Gt(val: val(), path: p)
        }
        if cur == ZincToken.gtEq {
            try consume()
            return try Ge(val: val(), path: p)
        }

        return Has(path: p)
    }

    private func path() throws -> Path {
        var id = try pathName()
        if cur != ZincToken.arrow {
            return Path(id)
        }

        var segments = [String]()
        segments.append(id)
        var s = id
        while cur == ZincToken.arrow {
            try consume(expected: ZincToken.arrow)
            id = try pathName()
            segments.append(id)
            s.append(ZincToken.arrow.rawValue)
            s.append(id)
        }
        return Path(s: s, n: segments)
    }

    private func pathName() throws -> String {
        if cur != ZincToken.id {
            throw ParseError.filter("Expecting tag name, not " + curToStr())
        }
        let id = curVal as! String
        try consume()
        return id
    }

    private func val() throws -> any Val {
        if let cur = cur, cur.isLiteral {
            let v = curVal
            try consume()
            return v
        }

        if cur == ZincToken.id {
            if "true".equals(curVal) {
                try consume()
                return true
            }
            if "false".equals(curVal) {
                try consume()
                return false
            }
        }

        throw ParseError.filter("Expecting value literal, not \(curToStr())")
    }

    private func isKeyword(_ n: String) -> Bool {
        return cur == ZincToken.id && n.equals(curVal)
    }

    private func verify(expected: ZincToken) throws {
        if cur != expected {
            throw ParseError.filter("Expected \(expected) not \(curToStr())")
        }
    }

    private func curToStr() -> String {
        if let cur = cur {
            return "\(cur) \(curVal)"
        } else {
            return Haystack.null.toZinc()
        }
    }

    private func consume() throws {
        try consume(expected: nil)
    }

    private func consume(expected: ZincToken?) throws {
        if let expected = expected {
            try verify(expected: expected)
        }
        cur = peek
        curVal = peekVal
        peek = try tokenizer.next()
        peekVal = tokenizer.val
    }
}
