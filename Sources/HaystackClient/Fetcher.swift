import Foundation

public protocol Fetcher {
    func fetch(_ request: HaystackRequest) async throws -> HaystackResponse
}

public struct HaystackResponse {
    public let statusCode: Int
    public let headerAuthenticationInfo: String?
    public let headerContentType: String?
    public let headerWwwAuthenticate: String?
    public let data: Data
    
    public init(
        statusCode: Int,
        headerAuthenticationInfo: String?,
        headerContentType: String?,
        headerWwwAuthenticate: String?,
        data: Data
    ) {
        self.statusCode = statusCode
        self.headerAuthenticationInfo = headerAuthenticationInfo
        self.headerContentType = headerContentType
        self.headerWwwAuthenticate = headerWwwAuthenticate
        self.data = data
    }
}

public struct HaystackRequest {
    public let method: HaystackHttpMethod
    public let url: String
    public let headerAuthorization: String
    public let headerUserAgent: String = "swift-haystack-client"
    public let headerAccept: String
    
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

public enum HaystackHttpMethod {
    case GET
    case POST(contentType: String, data: Data)
}
