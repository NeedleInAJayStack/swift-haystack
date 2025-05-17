import Foundation

/// Val represents the core functionality of Haystack types, specifically
/// hashability, equatability, JSON coding, and zinc coding.
public protocol Val: Codable, Hashable, Sendable {
    static var valType: ValType { get }
    func toZinc() -> String
}

extension Val {
    func equals(_ other: any Val) -> Bool {
        guard let otherAsMyType = other as? Self else {
            return false
        }

        return self == otherAsMyType
    }

    func coerce<T: Val>(to _: T.Type) throws -> T {
        guard let coercedSelf = self as? T else {
            throw ValError.cannotBeCoerced(toZinc(), T.valType)
        }
        return coercedSelf
    }
}

public enum ValType: String, CaseIterable {
    case Bool
    case Coord
    case Date
    case DateTime
    case Dict
    case Grid
    case List
    case Marker
    case NA
    case Null
    case Number
    case Ref
    case Remove
    case Str
    case Symbol
    case Time
    case Uri
    case XStr

    var type: any Val.Type {
        switch self {
        case .Bool: return Swift.Bool.self
        case .Coord: return Haystack.Coord.self
        case .Date: return Haystack.Date.self
        case .DateTime: return Haystack.DateTime.self
        case .Dict: return Haystack.Dict.self
        case .Grid: return Haystack.Grid.self
        case .List: return Haystack.List.self
        case .Marker: return Haystack.Marker.self
        case .NA: return Haystack.NA.self
        case .Null: return Haystack.Null.self
        case .Number: return Haystack.Number.self
        case .Ref: return Haystack.Ref.self
        case .Remove: return Haystack.Remove.self
        case .Str: return String.self
        case .Symbol: return Haystack.Symbol.self
        case .Time: return Haystack.Time.self
        case .Uri: return Haystack.Uri.self
        case .XStr: return Haystack.XStr.self
        }
    }
}
