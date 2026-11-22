import Foundation
import Testing
import Domain

@Suite("TripSummary")
struct TripSummaryTests {
    @Test func countsMemoriesAndPicksTheMostFrequentTags() {
        let japan = Trip(name: "Japan")
        let norway = Trip(name: "Norway")
        let entries = [
            Entry(tripID: japan.id, text: "a", tags: ["ramen", "happy"]),
            Entry(tripID: japan.id, text: "b", tags: ["ramen", "onsen"]),
            Entry(tripID: japan.id, text: "c", tags: ["onsen", "ramen", "tired"]),
            Entry(tripID: norway.id, text: "d", tags: ["fjord"]),
        ]

        let summaries = TripSummary.summaries(of: [japan, norway], entries: entries)

        #expect(summaries.map(\.memoryCount) == [3, 1])
        #expect(summaries[0].topTags == ["ramen", "onsen", "happy"])
        #expect(summaries[1].topTags == ["fjord"])
    }

    @Test func aTripWithoutEntriesHasNoTags() {
        let summary = TripSummary.summaries(of: [Trip(name: "Iceland")], entries: [])

        #expect(summary.first?.memoryCount == 0)
        #expect(summary.first?.topTags == [])
    }
}
