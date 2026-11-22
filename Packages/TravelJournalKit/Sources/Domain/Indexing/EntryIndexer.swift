/// Understands a saved entry. Receives the whole entry, so implementations can use its
/// deterministic metadata (place, weather, daytime) as context, not just the text.
public protocol EntryIndexer: Sendable {
    func index(_ entry: Entry) async throws -> EntryIndex
}
