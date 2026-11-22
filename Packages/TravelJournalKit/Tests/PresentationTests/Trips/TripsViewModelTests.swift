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
            media: MockMediaStore()
        ))
        let observingTrips = Task { await sut.observeTrips() }
        let observingEntries = Task { await sut.observeEntries() }
        defer { observingTrips.cancel(); observingEntries.cancel() }

        entries.send([Entry(tripID: japan.id, text: "ramen", tags: ["ramen"])])
        while sut.summaries.first?.memoryCount != 1 { await Task.yield() }

        #expect(sut.hasLoaded)
        #expect(sut.summaries.first?.topTags == ["ramen"])
    }
}
