import CoreSpotlight
import Foundation
import FoundationModels
import Testing
@testable import DataLayer

@Suite("Search prompt")
struct SearchPromptTests {
    private let iceCream = SearchCandidate(
        id: UUID(), title: "Black ice cream!", tripName: "Japan", place: "Owakudani, Hakone",
        keywords: ["ice cream", "volcano"], date: Date(timeIntervalSince1970: 1_795_000_000)
    )
    private let ramen = SearchCandidate(id: UUID(), title: "Ramen near the station")

    @Test func listsEachCandidateUnderAShortLabel() {
        let prompt = SearchPrompt.selectionPrompt(question: "black ice cream", candidates: [iceCream, ramen])

        #expect(prompt == """
            Question: black ice cream

            Entries:
            e1: Black ice cream! | trip: Japan | place: Owakudani, Hakone | tags: ice cream, volcano | Nov 18, 2026
            e2: Ramen near the station
            """)
    }

    /// The schema is the guarantee: the model can only answer with labels of entries the search found.
    @Test func theSchemaOffersOnlyTheFoundLabels() throws {
        let schema = try SearchPrompt.selectionSchema(candidateCount: 2)
        let json = String(decoding: try JSONEncoder().encode(schema), as: UTF8.self)

        #expect(json.contains("e1"))
        #expect(json.contains("e2"))
        #expect(!json.contains("e3"))
    }

    @Test func mapsChosenLabelsBackToEntriesInOrder() throws {
        let content = GeneratedContent(properties: ["entries": ["e2", "e1", "e2", "e9"]])

        #expect(try SearchPrompt.ids(from: content, candidates: [iceCream, ramen]) == [ramen.id, iceCream.id])
    }

    @Test func anEmptyChoiceMeansNothingFound() throws {
        let content = GeneratedContent(properties: ["entries": [String]()])

        #expect(try SearchPrompt.ids(from: content, candidates: [iceCream]).isEmpty)
    }

    @Test func overlappingQueriesKeepEachEntryOnce() {
        #expect(SearchPrompt.deduplicated([iceCream, ramen, iceCream]) == [iceCream, ramen])
    }

    @Test func readsACandidateFromTheIndexedItem() {
        let entryID = UUID()
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = "Ramen"
        attributes.containerTitle = "Japan"
        attributes.namedLocation = ""
        attributes.keywords = ["ramen"]
        let item = CSSearchableItem(uniqueIdentifier: entryID.uuidString, domainIdentifier: nil, attributeSet: attributes)

        #expect(SearchCandidate(item) == SearchCandidate(id: entryID, title: "Ramen", tripName: "Japan", keywords: ["ramen"]))
    }

    @Test func ignoresItemsThatAreNotEntries() {
        let item = CSSearchableItem(uniqueIdentifier: "not-an-entry", domainIdentifier: nil, attributeSet: CSSearchableItemAttributeSet(contentType: .text))

        #expect(SearchCandidate(item) == nil)
    }
}
