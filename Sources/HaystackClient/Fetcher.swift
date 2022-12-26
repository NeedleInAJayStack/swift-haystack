import Foundation

/// A protocol that abstracts HTTP data retrieval for Haystack.
public protocol Fetcher {
    /// Given a request, execute it across HTTP and return the result.
    ///
    /// - Parameter request: The request to execute
    /// - Returns: The result of executing the request
    func fetch(_ request: HaystackRequest) async throws -> HaystackResponse
}

/// An HTTP request for haystack data. It just collects relevant HTTP
/// artifacts, like binary data and select header values.
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

/// A response to a `HaystackRequest`. It just collects relevant HTTP
/// artifacts, like binary data and select header values.
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

/// The HTTP method to use in the `HaystackRequest`.  For more information, see
/// [Requests](https://project-haystack.org/doc/docHaystack/HttpApi#requests)
public enum HaystackHttpMethod {
    case GET
    case POST(contentType: String, data: Data)
}
