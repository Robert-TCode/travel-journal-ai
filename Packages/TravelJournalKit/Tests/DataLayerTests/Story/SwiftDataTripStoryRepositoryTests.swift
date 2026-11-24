import Domain
import Foundation
import Testing
@testable import DataLayer

@Suite("SwiftDataTripStoryRepository")
struct SwiftDataTripStoryRepositoryTests {
    @Test func storesOneStoryPerTripAndReplacesIt() async throws {
        let sut = try JournalStore.inMemory().stories
        let tripID = UUID()
        let first = TripStory(
            tripID: tripID, title: "First", text: "Text",
            highlights: [.init(entryID: UUID(), caption: "Ramen")],
            writer: .onDevice, fingerprint: "abc", createdAt: Date(timeIntervalSince1970: 100)
        )
        try await sut.save(first)
        #expect(try await sut.story(forTrip: tripID) == first)

        let second = TripStory(
            tripID: tripID, title: "Second", text: "Text", highlights: [],
            writer: .privateCloudCompute, fingerprint: "def", createdAt: Date(timeIntervalSince1970: 200)
        )
        try await sut.save(second)

        #expect(try await sut.story(forTrip: tripID) == second)
        #expect(try await sut.story(forTrip: UUID()) == nil)
    }
}
