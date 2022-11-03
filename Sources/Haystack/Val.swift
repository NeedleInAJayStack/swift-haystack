import Foundation

/// HVal is the base class for representing haystack tag
/// scalar values as an immutable class.
///
/// See [Project Haystack](http://project-haystack.org/doc/TagModel#tagKinds)
public protocol Val: Codable, Hashable {
    static var valType: ValType { get }
//    func toZinc() -> String
}

extension Val {
    func equals(_ other: any Val) -> Bool {
        guard let otherAsMyType = other as? Self else {
            return false
        }
        
        return self == otherAsMyType
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
