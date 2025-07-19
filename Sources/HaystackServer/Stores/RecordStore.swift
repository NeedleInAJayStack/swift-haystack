import Haystack

/// Defines a storage system that allows reading and writing of Haystack records.
public protocol RecordStore: Sendable {
    /// Reads records from the store based on a list of IDs.
    func read(ids: [Haystack.Ref]) async throws -> [Haystack.Dict]

    /// Reads records from the store based on a filter and an optional limit.
    func read(filter: String, limit: Haystack.Number?) async throws -> [Haystack.Dict]

    /// Commits a list of record diffs to the store.
    func commitAll(diffs: [RecordDiff]) async throws -> [RecordDiff]
}

public struct RecordDiff: Sendable {
    public init(
        id: Haystack.Ref,
        old: Haystack.Dict?,
        new: Haystack.Dict
    ) {
        self.id = id
        self.old = old
        self.new = new
    }

    public let id: Haystack.Ref
    public let old: Haystack.Dict?
    public let new: Haystack.Dict
}
