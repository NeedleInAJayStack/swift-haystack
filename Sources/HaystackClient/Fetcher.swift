import Foundation

protocol Fetcher {
    func fetch(_ request: Request) async throws -> Response
}

struct Response {
    let statusCode: Int
    let headerAuthenticationInfo: String?
    let headerContentType: String?
    let headerWwwAuthenticate: String?
    let data: Data
}

struct Request {
    let method: HaystackHttpMethod
    let url: String
    let headerAuthorization: String
    let headerUserAgent: String = "swift-haystack-client"
    let headerAccept: String
    
    init(
        method: HaystackHttpMethod = .GET,
        url: String,
        headerAuthorization: String,
        headerAccept: String = DataFormat.zinc.acceptHeaderValue
    ) {
        self.method = method
        self.url = url
        self.headerAuthorization = headerAuthorization
        self.headerAccept = headerAccept
    }
}

enum HaystackHttpMethod {
    case GET
    case POST(contentType: String, data: Data)
}
