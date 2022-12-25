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
    let method: HttpMethod
    let url: String
    let headerAuthorization: String
    let headerUserAgent: String = "swift-haystack-client"
    let headerAccept: String
    let headerContentType: String?
    let data: Data?
    
    init(
        method: HttpMethod = .GET,
        url: String,
        headerAuthorization: String,
        headerAccept: String = DataFormat.zinc.acceptHeaderValue,
        headerContentType: String? = nil,
        data: Data? = nil
    ) {
        self.method = method
        self.url = url
        self.headerAuthorization = headerAuthorization
        self.headerAccept = headerAccept
        self.headerContentType = headerContentType
        self.data = data
    }
}

enum HttpMethod: String {
    case GET
    case POST
}
