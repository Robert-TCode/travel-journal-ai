import Foundation
import SwiftData
import Testing
import Domain
@testable import DataLayer

@Suite("SwiftDataEntryRepository")
struct SwiftDataEntryRepositoryTests {
    private let tripID = UUID()

    @Test(.timeLimit(.minutes(1)))
    func emitsTheCurrentListThenEveryChange() async throws {
        let sut = try JournalStore.inMemory().entries
        var updates = await sut.entryUpdates(tripID: tripID).makeAsyncIterator()
        #expect(await updates.next() == [])

        let entry = Entry(tripID: tripID, text: "Walked 20k steps.")
        try await sut.save(entry)
        #expect(await updates.next() == [entry])

        let indexed = entry.applying(EntryIndex(tags: ["walking"], mood: nil))
        try await sut.save(indexed)
        #expect(await updates.next() == [indexed])
    }

    @Test(.timeLimit(.minutes(1)))
    func listsOnlyTheTripsEntriesNewestFirst() async throws {
        let sut = try JournalStore.inMemory().entries
        try await sut.save(Entry(tripID: tripID, text: "older", createdAt: Date(timeIntervalSince1970: 100)))
        try await sut.save(Entry(tripID: tripID, text: "newer", createdAt: Date(timeIntervalSince1970: 200)))
        try await sut.save(Entry(tripID: UUID(), text: "another trip"))

        var updates = await sut.entryUpdates(tripID: tripID).makeAsyncIterator()

        #expect(await updates.next()?.map(\.text) == ["newer", "older"])
    }

    @Test func roundTripsEveryField() async throws {
        let sut = try JournalStore.inMemory().entries
        let entry = Entry(
            tripID: tripID,
            text: "Black ice cream",
            photoNames: ["a.heic", "b.jpg"],
            audioName: "note.m4a",
            transcript: "Black ice cream at Owakudani",
            coordinate: Coordinate(latitude: 35.24, longitude: 139.02),
            placeName: "Hakone, Kanagawa",
            weather: .clear,
            isDaytime: true,
            tags: ["ice cream", "happy"],
            indexingStatus: .done
        )
        try await sut.save(entry)

        var updates = await sut.entryUpdates(tripID: tripID).makeAsyncIterator()

        #expect(await updates.next() == [entry])
    }

    @Test func pendingEntriesAreOnlyPendingOnesOldestFirst() async throws {
        let sut = try JournalStore.inMemory().entries
        try await sut.save(Entry(tripID: tripID, text: "newer", createdAt: Date(timeIntervalSince1970: 200)))
        try await sut.save(Entry(tripID: tripID, text: "older", createdAt: Date(timeIntervalSince1970: 100)))
        try await sut.save(Entry(tripID: tripID, text: "done", indexingStatus: .done))
        try await sut.save(Entry(tripID: tripID, text: "failed", indexingStatus: .failed))

        #expect(try await sut.pendingEntries().map(\.text) == ["older", "newer"])
    }

    /// What survives a relaunch: a second repository over the same store sees the first one's writes.
    @Test func anotherRepositoryOnTheSameStoreSeesSavedEntries() async throws {
        let container = try ModelContainer(for: EntryRecord.self, TripRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let entry = Entry(tripID: tripID, text: "Saved before relaunch")
        try await SwiftDataEntryRepository(container: container).save(entry)

        var updates = await SwiftDataEntryRepository(container: container).entryUpdates(tripID: tripID).makeAsyncIterator()

        #expect(await updates.next() == [entry])
    }

    @Test(.timeLimit(.minutes(1)))
    func allEntriesSpanEveryTrip() async throws {
        let sut = try JournalStore.inMemory().entries
        var updates = await sut.allEntryUpdates().makeAsyncIterator()
        #expect(await updates.next() == [])

        try await sut.save(Entry(tripID: tripID, text: "Japan"))
        _ = await updates.next()
        try await sut.save(Entry(tripID: UUID(), text: "Norway"))

        #expect(await updates.next()?.count == 2)
    }
}
