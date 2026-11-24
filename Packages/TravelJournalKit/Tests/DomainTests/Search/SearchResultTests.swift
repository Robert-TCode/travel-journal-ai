import Foundation
import Testing
import Domain

@Suite("Search results")
struct SearchResultTests {
    private let japan = Trip(name: "Japan")

    @Test func keepsTheSearchersOrderAndAddsTheTripName() {
        let ramen = Entry(tripID: japan.id, text: "Ramen")
        let gyoza = Entry(tripID: japan.id, text: "Gyoza")

        let results = SearchResult.results(for: [gyoza.id, ramen.id], entries: [ramen, gyoza], trips: [japan])

        #expect(results == [SearchResult(entry: gyoza, tripName: "Japan"), SearchResult(entry: ramen, tripName: "Japan")])
    }

    /// The Spotlight index can lag the store; a card must never point at nothing.
    @Test func dropsIDsThatAreNotStoredAndRepeats() {
        let ramen = Entry(tripID: japan.id, text: "Ramen")

        let results = SearchResult.results(for: [UUID(), ramen.id, ramen.id], entries: [ramen], trips: [japan])

        #expect(results.map(\.entry) == [ramen])
    }
}
