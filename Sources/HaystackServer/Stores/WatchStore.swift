import Foundation
import Haystack

/// Defines a storage system that allows stateful storage of system watches.
public protocol WatchStore {
    func read(watchId: String) async throws -> WatchResponse
    func create(ids: [Haystack.Ref], lease: Haystack.Number?) async throws -> String
    func addIds(watchId: String, ids: [Haystack.Ref]) async throws
    func removeIds(watchId: String, ids: [Haystack.Ref]) async throws
    func updateLastReported(watchId: String) async throws
    func delete(watchId: String) async throws
}

public struct WatchResponse {
    public let ids: [Haystack.Ref]
    public let lease: Haystack.Number
    public let lastReported: Foundation.Date?

    public init(ids: [Haystack.Ref], lease: Haystack.Number, lastReported: Foundation.Date?) {
        self.ids = ids
        self.lease = lease
        self.lastReported = lastReported
    }
}
