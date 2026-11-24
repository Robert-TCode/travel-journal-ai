import Foundation
import Testing
import Domain

@Suite("Search indexing on save")
struct SearchIndexingEntryRepositoryTests {
    private let japan = Trip(name: "Japan")
    private let store = SpyEntryRepository()

    @Test func indexesEverySavedEntryWithItsTripName() async throws {
        let index = SpySearchIndex()
        let sut = SearchIndexingEntryRepository(base: store, trips: FakeTripRepository(trips: [japan]), searchIndex: index)
        let entry = Entry(tripID: japan.id, text: "Black ice cream")

        try await sut.save(entry)

        #expect(store.entries == [entry])
        #expect(index.batches == [[SearchableEntry(entry: entry, tripName: "Japan")]])
    }

    /// Search is a convenience; the memory itself must never be lost to it.
    @Test func aFailingSearchIndexDoesNotFailTheSave() async throws {
        let sut = SearchIndexingEntryRepository(
            base: store,
            trips: FakeTripRepository(trips: [japan]),
            searchIndex: SpySearchIndex(failingWith: MockIndexerError())
        )
        let entry = Entry(tripID: japan.id, text: "Ferry to Miyajima")

        try await sut.save(entry)

        #expect(store.entries == [entry])
    }

    @Test(.timeLimit(.minutes(1)))
    func reindexesEveryStoredEntryInOneBatch() async throws {
        let norway = Trip(name: "Norway")
        let ramen = Entry(tripID: japan.id, text: "Ramen", createdAt: Date(timeIntervalSince1970: 200))
        let fjord = Entry(tripID: norway.id, text: "Fjord view", createdAt: Date(timeIntervalSince1970: 100))
        try await store.save(ramen)
        try await store.save(fjord)
        let index = SpySearchIndex()
        let sut = SearchIndexingEntryRepository(base: store, trips: FakeTripRepository(trips: [japan, norway]), searchIndex: index)

        await sut.reindexAll()

        #expect(index.batches == [[
            SearchableEntry(entry: ramen, tripName: "Japan"),
            SearchableEntry(entry: fjord, tripName: "Norway"),
        ]])
    }
}
