import Domain
import Foundation
import Testing
@testable import Presentation

private struct SearchFailed: Error {}

@MainActor
@Suite("Trips search")
struct TripsSearchTests {
    private let japan = Trip(name: "Japan")
    private let entries = MockEntryRepository()

    private func makeSUT(searcher: StubMemorySearcher) -> TripsViewModel {
        let trips = FakeTripRepository(trips: [japan])
        return TripsViewModel(dependencies: AppDependencies(
            availability: MockAvailabilityService(),
            entries: entries,
            trips: trips,
            tripLifecycle: TripLifecycle(repository: trips),
            indexingQueue: MockIndexingQueue(),
            context: StubContextProvider(),
            media: MockMediaStore(),
            recorder: MockVoiceRecorder(),
            liveIndexing: LiveIndexing(),
            searcher: searcher
        ))
    }

    /// Starts observing and waits until the view model holds the given entries. Cancel the returned task when done.
    private func observing(_ sut: TripsViewModel, _ stored: [Entry]) async -> Task<Void, Never> {
        let task = Task {
            async let trips: Void = sut.observeTrips()
            async let entries: Void = sut.observeEntries()
            _ = await (trips, entries)
        }
        entries.send(stored)
        while sut.summaries.first?.memoryCount != stored.count { await Task.yield() }
        return task
    }

    @Test(.timeLimit(.minutes(1)))
    func showsTheFoundEntriesInTheSearchersOrder() async {
        let ramen = Entry(tripID: japan.id, text: "Ramen")
        let iceCream = Entry(tripID: japan.id, text: "Black ice cream")
        let sut = makeSUT(searcher: StubMemorySearcher(result: .success([iceCream.id, ramen.id])))
        let task = await observing(sut, [ramen, iceCream])
        defer { task.cancel() }

        sut.query = "black ice cream"
        await sut.submitSearch()

        #expect(sut.search == .results([
            SearchResult(entry: iceCream, tripName: "Japan"),
            SearchResult(entry: ramen, tripName: "Japan"),
        ]))
    }

    @Test(.timeLimit(.minutes(1)))
    func nothingFoundIsAnEmptyResultNotAFailure() async {
        let sut = makeSUT(searcher: StubMemorySearcher(result: .success([])))
        let task = await observing(sut, [Entry(tripID: japan.id, text: "Ramen")])
        defer { task.cancel() }

        sut.query = "skiing"
        await sut.submitSearch()

        #expect(sut.search == .results([]))
    }

    @Test func aSearcherErrorShowsFailed() async {
        let sut = makeSUT(searcher: StubMemorySearcher(result: .failure(SearchFailed())))

        sut.query = "ramen"
        await sut.submitSearch()

        #expect(sut.search == .failed)
    }

    @Test func aBlankQueryClearsInsteadOfSearching() async {
        let sut = makeSUT(searcher: StubMemorySearcher(result: .failure(SearchFailed())))

        sut.query = "   "
        await sut.submitSearch()

        #expect(sut.search == .idle)
        #expect(sut.query.isEmpty)
    }

    /// A result card follows its entry, e.g. tags that arrive after the search.
    @Test(.timeLimit(.minutes(1)))
    func resultsFollowChangesToTheirEntries() async {
        var ramen = Entry(tripID: japan.id, text: "Ramen")
        let sut = makeSUT(searcher: StubMemorySearcher(result: .success([ramen.id])))
        let task = await observing(sut, [ramen])
        defer { task.cancel() }
        sut.query = "ramen"
        await sut.submitSearch()

        ramen.tags = ["ramen", "noodles"]
        entries.send([ramen])
        while sut.search != .results([SearchResult(entry: ramen, tripName: "Japan")]) { await Task.yield() }

        sut.clearSearch()
        #expect(sut.search == .idle)
    }
}
