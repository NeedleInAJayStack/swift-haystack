#if ServerVapor
import Haystack
import Vapor

extension Grid: Content {}

extension Request {
    /// Returns the grid parsed from the request body according to the `content-type` header
    func decodeGrid() throws -> Grid {
        let grid: Grid
        switch headers.contentType {
        case .zinc:
            guard let body = body.string else {
                throw Abort(.badRequest, reason: "No request body provided")
            }
            return try ZincReader(body).readGrid()
        default:
            grid = try content.decode(Grid.self)
        }
        return grid
    }

    /// Responds with the grid, encoded according to the `accept` header. See https://project-haystack.org/doc/docHaystack/HttpApi#contentNegotiation
    func respond(with grid: Grid) async throws -> Response {
        let accept = headers.accept
        if accept.isEmpty || accept.mediaTypes.contains(.zinc) {
            let response = Response(body: .init(stringLiteral: grid.toZinc()))
            response.headers.contentType = .zinc
            return response
        } else {
            return try await grid.encodeResponse(for: self)
        }
    }

    /// Extracts query parameters from the request URL. See https://project-haystack.org/doc/docHaystack/HttpApi#requests
    func queryDict() -> Dict {
        let queryItems = URLComponents(string: url.description)?.queryItems ?? []
        var dictMap: [String: any Val] = [:]
        for queryItem in queryItems {
            if let value = queryItem.value {
                // If we cannot parse the value as zinc, we should use the string value as per the spec
                dictMap[queryItem.name] = (try? (ZincReader(value).readVal())) ?? value
            }
        }
        return Dict(dictMap)
    }
}
#endif
