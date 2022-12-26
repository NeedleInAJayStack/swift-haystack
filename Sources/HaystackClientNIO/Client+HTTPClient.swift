import AsyncHTTPClient
import HaystackClient
import Foundation
import NIO

public extension Client {
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

