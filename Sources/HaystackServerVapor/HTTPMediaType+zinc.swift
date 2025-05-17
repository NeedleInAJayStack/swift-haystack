import Vapor

public extension HTTPMediaType {
    /// The `application/zinc` media type: https://project-haystack.org/doc/docHaystack/Zinc
    static let zinc = HTTPMediaType(type: "text", subType: "zinc", parameters: ["charset": "utf-8"])
}
