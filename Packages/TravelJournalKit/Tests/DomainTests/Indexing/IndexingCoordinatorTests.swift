import Foundation
import Testing
import Domain

@Suite("IndexingCoordinator")
struct IndexingCoordinatorTests {
    @Test(.timeLimit(.minutes(1)))
    func storesTheIndexedEntry() async {
        let repository = SpyEntryRepository()
        let sut = IndexingCoordinator(
            contextProvider: StubContextProvider(),
            indexer: MockEntryIndexer(returning: .success(EntryIndex(tags: ["walking"], mood: .tired))),
            repository: repository
        )
        let entry = Entry(tripID: UUID(), text: "Walked 20k steps.")

        await sut.enqueue(entry)
        await sut.waitUntilIdle()

        #expect(repository.entries.first?.id == entry.id)
        #expect(repository.entries.first?.tags == ["walking", "tired"])
        #expect(repository.entries.first?.indexingStatus == .done)
    }

    @Test(.timeLimit(.minutes(1)))
    func marksTheEntryFailedWhenTheModelFails() async {
        let repository = SpyEntryRepository()
        let sut = IndexingCoordinator(
            contextProvider: StubContextProvider(),
            indexer: MockEntryIndexer(returning: .failure(MockIndexerError())),
            repository: repository
        )

        await sut.enqueue(Entry(tripID: UUID(), text: "Some note"))
        await sut.waitUntilIdle()

        #expect(repository.entries.first?.indexingStatus == .failed)
        #expect(repository.entries.first?.text == "Some note")
    }

    @Test(.timeLimit(.minutes(1)))
    func indexesOneAtATimeInSaveOrder() async {
        let indexer = MockEntryIndexer(returning: .success(EntryIndex(tags: ["t"], mood: nil)))
        let sut = IndexingCoordinator(contextProvider: StubContextProvider(), indexer: indexer, repository: SpyEntryRepository())

        for text in ["first", "second", "third"] {
            await sut.enqueue(Entry(tripID: UUID(), text: text))
        }
        await sut.waitUntilIdle()

        #expect(indexer.indexedTexts == ["first", "second", "third"])
        #expect(indexer.maxConcurrentCalls == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func addsContextBeforeTheModelSeesTheEntry() async {
        let context = EntryContext(
            coordinate: Coordinate(latitude: 35.24, longitude: 139.02),
            placeName: "Hakone, Kanagawa"
        )
        let indexer = MockEntryIndexer(returning: .success(EntryIndex(tags: ["ice cream"], mood: .happy)))
        let repository = SpyEntryRepository()
        let sut = IndexingCoordinator(contextProvider: StubContextProvider(context: context), indexer: indexer, repository: repository)

        await sut.enqueue(Entry(tripID: UUID(), text: "Black ice cream!"))
        await sut.waitUntilIdle()

        #expect(indexer.receivedEntries.first?.placeName == "Hakone, Kanagawa")
        #expect(repository.entries.first?.coordinate == context.coordinate)
        #expect(repository.entries.first?.placeName == "Hakone, Kanagawa")
    }

    @Test(.timeLimit(.minutes(1)))
    func indexesEvenWithoutAnyContext() async {
        let repository = SpyEntryRepository()
        let sut = IndexingCoordinator(
            contextProvider: StubContextProvider(),
            indexer: MockEntryIndexer(returning: .success(EntryIndex(tags: ["bus"], mood: nil))),
            repository: repository
        )

        await sut.enqueue(Entry(tripID: UUID(), text: "Bus leaves at 9."))
        await sut.waitUntilIdle()

        #expect(repository.entries.first?.placeName == nil)
        #expect(repository.entries.first?.indexingStatus == .done)
    }

    @Test(.timeLimit(.minutes(1)))
    func resumesPendingEntriesOldestFirstWithoutRefetchingContext() async throws {
        let repository = SpyEntryRepository()
        let older = Entry(tripID: UUID(), text: "older", createdAt: Date(timeIntervalSince1970: 100), placeName: "Bergen")
        let newer = Entry(tripID: UUID(), text: "newer", createdAt: Date(timeIntervalSince1970: 200))
        let done = Entry(tripID: UUID(), text: "done", tags: ["x"], indexingStatus: .done)
        for entry in [newer, done, older] { try await repository.save(entry) }
        let contextProvider = StubContextProvider(context: EntryContext(placeName: "Today's place"))
        let indexer = MockEntryIndexer(returning: .success(EntryIndex(tags: ["t"], mood: nil)))
        let sut = IndexingCoordinator(contextProvider: contextProvider, indexer: indexer, repository: repository)

        await sut.resumePendingEntries()
        await sut.waitUntilIdle()

        #expect(indexer.indexedTexts == ["older", "newer"])
        #expect(contextProvider.callCount == 0)
        #expect(repository.entries.first { $0.id == older.id }?.placeName == "Bergen")
        #expect(repository.entries.allSatisfy { $0.indexingStatus == .done })
    }
}
