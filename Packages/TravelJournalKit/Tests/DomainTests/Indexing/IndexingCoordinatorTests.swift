import Foundation
import Testing
import Domain

@Suite("IndexingCoordinator")
struct IndexingCoordinatorTests {
    @Test(.timeLimit(.minutes(1)))
    func storesTheIndexedEntry() async {
        let repository = SpyEntryRepository()
        let sut = IndexingCoordinator(
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
        let sut = IndexingCoordinator(indexer: MockEntryIndexer(returning: .failure(MockIndexerError())), repository: repository)

        await sut.enqueue(Entry(tripID: UUID(), text: "Some note"))
        await sut.waitUntilIdle()

        #expect(repository.entries.first?.indexingStatus == .failed)
        #expect(repository.entries.first?.text == "Some note")
    }

    @Test(.timeLimit(.minutes(1)))
    func indexesOneAtATimeInSaveOrder() async {
        let indexer = MockEntryIndexer(returning: .success(EntryIndex(tags: ["t"], mood: nil)))
        let sut = IndexingCoordinator(indexer: indexer, repository: SpyEntryRepository())

        for text in ["first", "second", "third"] {
            await sut.enqueue(Entry(tripID: UUID(), text: text))
        }
        await sut.waitUntilIdle()

        #expect(indexer.indexedTexts == ["first", "second", "third"])
        #expect(indexer.maxConcurrentCalls == 1)
    }
}
