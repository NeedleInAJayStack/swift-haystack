import Foundation
import HaystackClient

public extension Client {
    convenience init(
        baseUrl: String,
        username: String,
        password: String,
        format: DataFormat = .zinc
    ) throws {
        let fetcher = URLSessionFetcher()
        try self.init(
            baseUrl: baseUrl,
            username: username,
            password: password,
            format: format,
            fetcher: fetcher
        )
    }
}
