import AsyncHTTPClient
import HaystackAPI
import HaystackClient
import Foundation
import NIO

public extension Client {
    
    /// Create a Haystack API Client that uses a NIO-based HTTP client.
    ///
    /// - Parameters:
    ///   - baseUrl: The URL of the Haystack API server
    ///   - username: The username to authenticate with
    ///   - password: The password to authenticate with
    ///   - format: The transfer data format. Defaults to `zinc` to reduce data transfer.
    ///   - eventLoopGroup: The event loop group on which to create request callbacks
    convenience init(
        baseUrl: String,
        username: String,
        password: String,
        format: DataFormat = .zinc,
        eventLoopGroup: EventLoopGroup
    ) throws {
        let fetcher = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup)).haystackFetcher()
        try self.init(
            baseUrl: baseUrl,
            username: username,
            password: password,
            format: format,
            fetcher: fetcher
        )
    }
}

