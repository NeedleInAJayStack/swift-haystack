import Foundation
import HaystackClient

public extension Client {
    /// Create a Haystack API Client that uses a `URLSession` from `Foundation` that
    /// is only available on Darwin platforms.
    ///
    /// - Parameters:
    ///   - baseUrl: The URL of the Haystack API server
    ///   - username: The username to authenticate with
    ///   - password: The password to authenticate with
    ///   - format: The transfer data format. Defaults to `zinc` to reduce data transfer.
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
