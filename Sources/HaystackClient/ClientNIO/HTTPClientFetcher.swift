#if ClientNIO
import AsyncHTTPClient
import Foundation
import NIO
import NIOFoundationCompat

extension HTTPClient {
    func haystackFetcher() -> HTTPClientFetcher {
        return HTTPClientFetcher(self)
    }
}

/// A Haystack API Client fetcher based on a NIO `HTTPClient`. This is only available on all platforms,
/// but includes many more dependencies than Foundation's `URLSession`
struct HTTPClientFetcher: Fetcher {
    let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }

    func fetch(_ request: HaystackRequest) async throws -> HaystackResponse {
        var httpClientRequest = HTTPClientRequest(url: request.url)

        switch request.method {
        case .GET:
            httpClientRequest.method = .GET
        case let .POST(contentType, data):
            httpClientRequest.method = .POST
            httpClientRequest.headers.add(name: HTTPHeader.contentType, value: contentType)
            httpClientRequest.body = .bytes(ByteBuffer(data: data))
        }
        httpClientRequest.headers.add(name: HTTPHeader.authorization, value: request.headerAuthorization)

        // See Content Negotiation: https://haxall.io/doc/docHaystack/HttpApi.html#contentNegotiation
        httpClientRequest.headers.add(name: HTTPHeader.accept, value: request.headerAccept)
        httpClientRequest.headers.add(name: HTTPHeader.userAgent, value: request.headerUserAgent)

        let response = try await client.execute(httpClientRequest, timeout: .seconds(30))

        let data = try await response.body.reduce(into: Data()) { partialResult, byteBuffer in
            partialResult.append(byteBuffer.getData(at: 0, length: byteBuffer.readableBytes)!)
        }

        return HaystackResponse(
            statusCode: Int(response.status.code),
            headerAuthenticationInfo: response.headers.first(name: HTTPHeader.authenticationInfo),
            headerContentType: response.headers.first(name: HTTPHeader.contentType),
            headerWwwAuthenticate: response.headers.first(name: HTTPHeader.wwwAuthenticate),
            data: data
        )
    }
}
#endif
