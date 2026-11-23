/// Understands a saved entry. Receives the whole entry, so implementations can use its
/// deterministic metadata (place, weather, daytime) as context, not just the text.
public protocol EntryIndexer: Sendable {
    /// `onPartial` receives what the model has produced so far, for display only: tags can be cut mid-word
    /// and the mood is left out until the end. The returned index is the only one to store.
    func index(_ entry: Entry, onPartial: @Sendable (EntryIndex) async -> Void) async throws -> EntryIndex
}
