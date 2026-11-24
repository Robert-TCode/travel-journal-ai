import Foundation
import Testing
import Domain

private struct StoryWriterStub: TripStoryWriter {
    let draft: @Sendable (_ entries: [Entry]) -> TripStory.Draft

    var writer: TripStory.Writer { .onDevice }

    func write(trip: Trip, entries: [Entry]) async throws -> TripStory.Draft {
        draft(entries)
    }
}

private actor StoryStore: TripStoryRepository {
    private(set) var saved: [TripStory] = []

    func story(forTrip tripID: UUID) -> TripStory? { saved.last { $0.tripID == tripID } }
    func save(_ story: TripStory) { saved.append(story) }
}

@Suite("Trip story")
struct TripStoryServiceTests {
    private let trip = Trip(name: "Japan")
    private let store = StoryStore()
    private let date = Date(timeIntervalSince1970: 1_000)

    private func makeSUT(_ draft: @escaping @Sendable ([Entry]) -> TripStory.Draft) -> TripStoryService {
        TripStoryService(writer: StoryWriterStub(draft: draft), repository: store, now: { [date] in date })
    }

    @Test func writesOldestFirstAndKeepsOnlyHighlightsOfRealEntries() async throws {
        let ramen = Entry(tripID: trip.id, text: "Ramen", createdAt: Date(timeIntervalSince1970: 200))
        let temple = Entry(tripID: trip.id, text: "Temple", createdAt: Date(timeIntervalSince1970: 100))
        let sut = makeSUT { entries in
            #expect(entries.map(\.text) == ["Temple", "Ramen"])
            return TripStory.Draft(title: "Japan", text: "Story", highlights: [
                .init(entryID: ramen.id, caption: "Dinner"),
                .init(entryID: UUID(), caption: "Invented"),
                .init(entryID: ramen.id, caption: "Again"),
            ])
        }

        let story = try await sut.writeStory(for: trip, entries: [ramen, temple])

        #expect(story.highlights == [.init(entryID: ramen.id, caption: "Dinner")])
        #expect(story.writer == .onDevice)
        #expect(story.createdAt == date)
        #expect(await store.saved == [story])
    }

    /// Opening a trip never calls the model: a stored story shows instantly, marked outdated once entries change.
    @Test func aStoredStoryIsCurrentUntilAnEntryChanges() async throws {
        var ramen = Entry(tripID: trip.id, text: "Ramen", tags: ["ramen"])
        let sut = makeSUT { _ in TripStory.Draft(title: "T", text: "S", highlights: []) }
        _ = try await sut.writeStory(for: trip, entries: [ramen])

        #expect(await sut.storedStory(for: trip, entries: [ramen])?.isCurrent == true)

        ramen.tags.append("noodles")
        #expect(await sut.storedStory(for: trip, entries: [ramen])?.isCurrent == false)
        #expect(await sut.storedStory(for: trip, entries: [ramen, Entry(tripID: trip.id, text: "New")])?.isCurrent == false)
    }

    @Test func aTripWithoutStoryHasNothingStored() async {
        let sut = makeSUT { _ in TripStory.Draft(title: "", text: "", highlights: []) }

        #expect(await sut.storedStory(for: trip, entries: []) == nil)
    }

    @Test func aTripWithoutEntriesHasNoStoryToTell() async {
        let sut = makeSUT { _ in TripStory.Draft(title: "", text: "", highlights: []) }

        await #expect(throws: TripStoryError.noEntries) {
            try await sut.writeStory(for: trip, entries: [])
        }
    }

    /// Stored next to the story, so it must not depend on order or on Swift's per-launch hash seed.
    @Test func theFingerprintIgnoresOrderAndIsStable() {
        let a = Entry(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, tripID: trip.id, text: "A")
        let b = Entry(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, tripID: trip.id, text: "B")

        #expect(TripStory.fingerprint(of: [a, b]) == TripStory.fingerprint(of: [b, a]))
        #expect(TripStory.fingerprint(of: [a, b]) == "bd716d8ac1e3c935")
    }
}
