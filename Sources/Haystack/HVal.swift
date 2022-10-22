/// HVal is the base class for representing haystack tag
/// scalar values as an immutable class.
///
/// See [Project Haystack](http://project-haystack.org/doc/TagModel#tagKinds)
public protocol HVal: Codable, Comparable, Hashable {
    func toZinc() -> String
}
