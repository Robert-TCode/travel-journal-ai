import DesignSystem
import Domain
import Foundation
import Testing
@testable import Presentation

@MainActor
@Suite("TripsViewModel")
struct TripsViewModelTests {
    @Test(.timeLimit(.minutes(1)))
    func summarizesEachTripWithItsEntries() async {
        let japan = Trip(name: "Japan")
        let trips = FakeTripRepository(trips: [japan])
        let entries = MockEntryRepository()
        let sut = TripsViewModel(dependencies: AppDependencies(
            availability: MockAvailabilityService(),
            entries: entries,
            trips: trips,
            tripLifecycle: TripLifecycle(repository: trips),
            indexingQueue: MockIndexingQueue(),
            context: StubContextProvider(),
            media: MockMediaStore(),
            recorder: MockVoiceRecorder(),
            liveIndexing: LiveIndexing(),
            searcher: StubMemorySearcher()
        ))
        let observingTrips = Task { await sut.observeTrips() }
        let observingEntries = Task { await sut.observeEntries() }
        defer { observingTrips.cancel(); observingEntries.cancel() }

        let ramen = Entry(tripID: japan.id, text: "ramen", weather: .rainy, tags: ["ramen"])
        entries.send([ramen])
        while sut.summaries.first?.memoryCount != 1 { await Task.yield() }

        #expect(sut.hasLoaded)
        #expect(sut.summaries.first?.topTags == ["ramen"])
        #expect(sut.skies[japan.id] == Sky(entry: ramen))
    }
}
