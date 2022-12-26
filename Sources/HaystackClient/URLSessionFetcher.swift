import Foundation

// URLSession IS NOT AVAILABLE ON LINUX!
struct URLSessionFetcher: Fetcher {
    let session: URLSession
    
    init() {
        // Disable all cookies, otherwise haystack thinks we're a browser client
        // and asks for an Attest-Key header
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpCookieAcceptPolicy = .never
        sessionConfig.httpShouldSetCookies = false
        sessionConfig.httpCookieStorage = nil
        self.session = URLSession(configuration: sessionConfig)
    }
    
    func fetch(_ request: Request) async throws -> Response {
        guard let url = URL(string: request.url) else {
            throw HaystackClientError.invalidUrl(request.url)
        }
        
        var urlRequest = URLRequest(url: url)
        
        switch request.method {
        case .GET:
            urlRequest.httpMethod = "GET"
        case let .POST(contentType, data):
            urlRequest.httpMethod = "POST"
            urlRequest.addValue(contentType, forHTTPHeaderField: HTTPHeader.contentType)
            urlRequest.httpBody = data
        }
        urlRequest.addValue(request.headerAuthorization, forHTTPHeaderField: HTTPHeader.authorization)
        
        // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
        urlRequest.addValue(request.headerAccept, forHTTPHeaderField: HTTPHeader.accept)
        urlRequest.addValue(request.headerUserAgent, forHTTPHeaderField: HTTPHeader.userAgent)
        let (data, responseGen) = try await session.data(for: urlRequest)
        let response = (responseGen as! HTTPURLResponse)
        return Response(
            statusCode: response.statusCode,
            headerAuthenticationInfo: response.value(forHTTPHeaderField: HTTPHeader.authenticationInfo),
            headerContentType: response.value(forHTTPHeaderField: HTTPHeader.contentType),
            headerWwwAuthenticate: response.value(forHTTPHeaderField: HTTPHeader.wwwAuthenticate),
            data: data
        )
    }
}
