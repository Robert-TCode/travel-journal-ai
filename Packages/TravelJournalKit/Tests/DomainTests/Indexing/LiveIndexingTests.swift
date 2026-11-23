import Foundation
import Synchronization
import Testing
import Domain

/// Streams the given partial indexes and records what `LiveIndexing` shows after each one,
/// which is exactly what a screen would render at that moment.
private final class PreviewRecordingIndexer: EntryIndexer {
    private let live: LiveIndexing
    private let partials: [EntryIndex]
    private let result: Result<EntryIndex, any Error>
    private let seen = Mutex<[Entry?]>([])

    init(live: LiveIndexing, partials: [EntryIndex], returning result: Result<EntryIndex, any Error>) {
        self.live = live
        self.partials = partials
        self.result = result
    }

    var previews: [Entry?] { seen.withLock { $0 } }

    func index(_ entry: Entry, onPartial: @Sendable (EntryIndex) async -> Void) async throws -> EntryIndex {
        for partial in partials {
            await onPartial(partial)
            let preview = await live.preview(of: entry)
            seen.withLock { $0.append(preview) }
        }
        return try result.get()
    }
}

@Suite("Live indexing")
struct LiveIndexingTests {
    private let live = LiveIndexing()
    private let repository = SpyEntryRepository()

    private func coordinator(_ indexer: some EntryIndexer) -> IndexingCoordinator {
        IndexingCoordinator(
            contextProvider: StubContextProvider(),
            transcriber: StubTranscriber(),
            indexer: indexer,
            repository: repository,
            live: live
        )
    }

    @Test(.timeLimit(.minutes(1)))
    func showsTagsAsTheyArriveThenLeavesOnlyTheStoredEntry() async {
        let indexer = PreviewRecordingIndexer(
            live: live,
            partials: [EntryIndex(tags: ["ram"], mood: nil), EntryIndex(tags: ["ramen", "gyoza"], mood: nil)],
            returning: .success(EntryIndex(tags: ["ramen", "gyoza"], mood: .happy))
        )
        let entry = Entry(tripID: UUID(), text: "Ramen near the station")

        let sut = coordinator(indexer)
        await sut.enqueue(entry)
        await sut.waitUntilIdle()

        #expect(indexer.previews.map { $0?.tags } == [["ram"], ["ramen", "gyoza"]])
        #expect(indexer.previews.allSatisfy { $0?.indexingStatus == .pending })
        #expect(await live.preview(of: entry) == nil)
        #expect(repository.entries.first?.tags == ["ramen", "gyoza", "happy"])
    }

    /// The preview follows the same rules as the stored result, so nothing shows up live only to vanish at the end.
    @Test(.timeLimit(.minutes(1)))
    func previewDropsMoodWordsAndHalfWrittenLandmarks() async {
        let indexer = PreviewRecordingIndexer(
            live: live,
            partials: [
                EntryIndex(tags: ["Black Ice Cream ", "happy"], mood: nil, landmark: "Owaku"),
                EntryIndex(tags: ["black ice cream"], mood: nil, landmark: "Owakudani"),
            ],
            returning: .success(EntryIndex(tags: ["black ice cream"], mood: nil, landmark: "Owakudani"))
        )
        let entry = Entry(tripID: UUID(), text: "Black ice cream!", nearbyPlaces: ["Owakudani"])
        let sut = coordinator(indexer)

        await sut.enqueue(entry)
        await sut.waitUntilIdle()

        #expect(indexer.previews.first??.tags == ["black ice cream"])
        #expect(indexer.previews.first??.landmark == nil)
        #expect(indexer.previews.last??.landmark == "Owakudani")
    }

    @Test(.timeLimit(.minutes(1)))
    func clearsThePreviewWhenTheModelIsBusy() async {
        let indexer = PreviewRecordingIndexer(
            live: live,
            partials: [EntryIndex(tags: ["ferry"], mood: nil)],
            returning: .failure(IndexingError.temporarilyUnavailable)
        )
        let entry = Entry(tripID: UUID(), text: "Ferry to Miyajima")
        let sut = coordinator(indexer)

        await sut.enqueue(entry)
        await sut.waitUntilIdle()

        #expect(indexer.previews.first??.tags == ["ferry"])
        #expect(await live.preview(of: entry) == nil)
        #expect(repository.entries.first?.indexingStatus == .pending)
    }
}
