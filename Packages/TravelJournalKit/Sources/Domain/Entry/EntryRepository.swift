/// Stores entries. Saving never involves the model, so a memory is never lost to an AI failure.
public protocol EntryRepository: Sendable {
    /// Inserts the entry, or replaces the stored one with the same `id` (used when indexing adds metadata).
    func save(_ entry: Entry) async throws
}
