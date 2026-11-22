import Foundation
import Testing
import Domain

@Suite("TripLifecycle")
struct TripLifecycleTests {
    @Test func startsATripWithATrimmedName() async throws {
        let repository = FakeTripRepository()
        let sut = TripLifecycle(repository: repository)

        let trip = try await sut.start(named: "  Japan  ")

        #expect(trip.name == "Japan")
        #expect(trip.isOngoing)
        #expect(repository.trips == [trip])
    }

    @Test func refusesAnEmptyName() async {
        let sut = TripLifecycle(repository: FakeTripRepository())

        await #expect(throws: TripLifecycleError.emptyName) {
            try await sut.start(named: "   ")
        }
    }

    @Test func refusesASecondOngoingTrip() async throws {
        let repository = FakeTripRepository(trips: [Trip(name: "Japan")])
        let sut = TripLifecycle(repository: repository)

        await #expect(throws: TripLifecycleError.anotherTripIsOngoing) {
            try await sut.start(named: "Norway")
        }
        #expect(repository.trips.count == 1)
    }

    @Test func endingATripAllowsTheNextOne() async throws {
        let repository = FakeTripRepository()
        let sut = TripLifecycle(repository: repository)
        let japan = try await sut.start(named: "Japan")

        try await sut.end(japan)
        _ = try await sut.start(named: "Norway")

        #expect(repository.trips.map(\.name) == ["Norway", "Japan"])
        #expect(repository.trips.filter(\.isOngoing).map(\.name) == ["Norway"])
    }

    /// Two quick taps on "Start trip": both calls interleave at `await`, only one may win.
    @Test func concurrentStartsCreateOnlyOneTrip() async {
        let repository = FakeTripRepository()
        let sut = TripLifecycle(repository: repository)

        async let first = try? sut.start(named: "Japan")
        async let second = try? sut.start(named: "Japan")
        _ = await (first, second)

        #expect(repository.trips.count == 1)
    }
}
