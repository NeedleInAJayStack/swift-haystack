import Vapor

public extension HTTPMediaType {
    static let zinc = HTTPMediaType(type: "text", subType: "zinc", parameters: ["charset": "utf-8"])
}
