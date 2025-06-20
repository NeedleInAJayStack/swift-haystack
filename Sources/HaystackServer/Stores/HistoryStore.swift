import Haystack

/// Defines a storage system that allows reading and writing of Haystack history data.
public protocol HistoryStore: Sendable {
    /// Reads history data for a given ID and time range.
    func hisRead(id: Haystack.Ref, range: Haystack.HisReadRange) async throws -> [Haystack.Dict]

    /// Writes history data for a given ID.
    func hisWrite(id: Haystack.Ref, items: [Haystack.HisItem]) async throws
}
