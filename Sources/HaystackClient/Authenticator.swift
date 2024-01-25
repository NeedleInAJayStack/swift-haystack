@available(macOS 10.15, *)
protocol Authenticator {
    func getAuthToken() async throws -> String
}
