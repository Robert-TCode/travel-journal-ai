import Foundation
import Testing
import Domain
@testable import DataLayer

@Suite("InMemoryEntryRepository")
struct InMemoryEntryRepositoryTests {
    private let tripID = UUID()

    @Test(.timeLimit(.minutes(1)))
    func emitsTheCurrentListThenEveryChange() async {
        let sut = InMemoryEntryRepository()
        var updates = await sut.entryUpdates(tripID: tripID).makeAsyncIterator()
        #expect(await updates.next() == [])

        let entry = Entry(tripID: tripID, text: "Walked 20k steps.")
        await sut.save(entry)
        #expect(await updates.next() == [entry])

        let indexed = entry.applying(EntryIndex(tags: ["walking"], mood: nil))
        await sut.save(indexed)
        #expect(await updates.next() == [indexed])
    }

    @Test(.timeLimit(.minutes(1)))
    func listsOnlyTheTripsEntriesNewestFirst() async {
        let sut = InMemoryEntryRepository()
        let older = Entry(tripID: tripID, text: "older", createdAt: Date(timeIntervalSince1970: 100))
        let newer = Entry(tripID: tripID, text: "newer", createdAt: Date(timeIntervalSince1970: 200))
        await sut.save(older)
        await sut.save(newer)
        await sut.save(Entry(tripID: UUID(), text: "another trip"))

        var updates = await sut.entryUpdates(tripID: tripID).makeAsyncIterator()

        #expect(await updates.next()?.map(\.text) == ["newer", "older"])
    }
}
