import Foundation

/// Keeps the search index in step with the store: every saved version of an entry is indexed right after it is stored,
/// so a note is findable by its words at once and by its tags once indexing adds them.
/// Search is a convenience: a failure to index never fails the save, and the next launch's `reindexAll()` repairs it.
public struct SearchIndexingEntryRepository: EntryRepository {
    private let base: any EntryRepository
    private let trips: any TripRepository
    private let searchIndex: any EntrySearchIndex

    public init(base: any EntryRepository, trips: any TripRepository, searchIndex: any EntrySearchIndex) {
        self.base = base
        self.trips = trips
        self.searchIndex = searchIndex
    }

    public func save(_ entry: Entry) async throws {
        try await base.save(entry)
        let tripName = try? await trips.trip(withID: entry.tripID)?.name
        try? await searchIndex.index([SearchableEntry(entry: entry, tripName: tripName)])
    }

    public func entryUpdates(tripID: UUID) async -> AsyncStream<[Entry]> {
        await base.entryUpdates(tripID: tripID)
    }

    public func allEntryUpdates() async -> AsyncStream<[Entry]> {
        await base.allEntryUpdates()
    }

    public func pendingEntries() async throws -> [Entry] {
        try await base.pendingEntries()
    }

    /// Indexes everything already stored: entries saved before search existed, or while indexing failed.
    public func reindexAll() async {
        var allTrips = await trips.tripUpdates().makeAsyncIterator()
        var allEntries = await base.allEntryUpdates().makeAsyncIterator()
        let tripNames = Dictionary(((await allTrips.next()) ?? []).map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let entries = (await allEntries.next()) ?? []
        try? await searchIndex.index(entries.map { SearchableEntry(entry: $0, tripName: tripNames[$0.tripID]) })
    }
}
