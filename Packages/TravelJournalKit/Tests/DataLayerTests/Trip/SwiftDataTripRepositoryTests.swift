import Foundation
import Testing
import Domain
@testable import DataLayer

@Suite("SwiftDataTripRepository")
struct SwiftDataTripRepositoryTests {
    @Test(.timeLimit(.minutes(1)))
    func listsTripsNewestFirstAndFollowsChanges() async throws {
        let sut = try JournalStore.inMemory().trips
        var updates = await sut.tripUpdates().makeAsyncIterator()
        #expect(await updates.next() == [])

        let norway = Trip(name: "Norway", startedAt: Date(timeIntervalSince1970: 100), endedAt: Date(timeIntervalSince1970: 200))
        try await sut.save(norway)
        _ = await updates.next()
        let japan = Trip(name: "Japan", startedAt: Date(timeIntervalSince1970: 300))
        try await sut.save(japan)

        #expect(await updates.next()?.map(\.name) == ["Japan", "Norway"])
    }

    @Test func findsTheOngoingTripUntilItEnds() async throws {
        let sut = try JournalStore.inMemory().trips
        var japan = Trip(name: "Japan")
        try await sut.save(japan)
        #expect(try await sut.ongoingTrip() == japan)

        japan.endedAt = .now
        try await sut.save(japan)

        #expect(try await sut.ongoingTrip() == nil)
    }
}
