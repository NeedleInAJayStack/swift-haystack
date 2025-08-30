#if ClientDarwin
import Foundation

/// A Haystack API Client fetcher based on `URLSession`. This is only available on Darwin platforms.
struct URLSessionFetcher: Fetcher {
    let session: URLSession

    init() {
        // Disable all cookies, otherwise haystack thinks we're a browser client
        // and asks for an Attest-Key header
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpCookieAcceptPolicy = .never
        sessionConfig.httpShouldSetCookies = false
        sessionConfig.httpCookieStorage = nil
        session = URLSession(configuration: sessionConfig)
    }

    func fetch(_ request: HaystackRequest) async throws -> HaystackResponse {
        guard let url = URL(string: request.url) else {
            throw URLSessionFetcherError.invalidUrl(request.url)
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
        return HaystackResponse(
            statusCode: response.statusCode,
            headerAuthenticationInfo: response.value(forHTTPHeaderField: HTTPHeader.authenticationInfo),
            headerContentType: response.value(forHTTPHeaderField: HTTPHeader.contentType),
            headerWwwAuthenticate: response.value(forHTTPHeaderField: HTTPHeader.wwwAuthenticate),
            data: data
        )
    }
}

public enum URLSessionFetcherError: Error {
    case invalidUrl(String)
}
#endif
