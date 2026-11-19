/// Stores entries. Saving never involves the model, so a memory is never lost to an AI failure.
public protocol EntryRepository: Sendable {
    func save(_ entry: Entry) async throws
}
