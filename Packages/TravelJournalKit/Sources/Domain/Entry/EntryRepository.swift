import Foundation

/// Saving never involves the model, so a memory is never lost to an AI failure.
public protocol EntryRepository: Sendable {
    /// Inserts the entry, or replaces the stored one with the same `id`.
    func save(_ entry: Entry) async throws

    /// The trip's entries, newest first: the current list right away, then a new list after every change.
    /// Each call returns a new stream, so every screen gets its own.
    func entryUpdates(tripID: UUID) async -> AsyncStream<[Entry]>

    /// Every trip's entries, newest first, with the same delivery as `entryUpdates(tripID:)`.
    func allEntryUpdates() async -> AsyncStream<[Entry]>

    /// Entries whose indexing never finished, oldest first, so they can be resumed after a restart.
    func pendingEntries() async throws -> [Entry]
}
