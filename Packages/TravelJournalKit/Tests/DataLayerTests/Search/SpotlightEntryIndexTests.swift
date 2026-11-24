import CoreSpotlight
import Foundation
import Testing
import Domain
@testable import DataLayer

/// Checks the mapping only: what `SpotlightSearchTool` and the system search will be able to match.
@Suite("Spotlight entry index")
struct SpotlightEntryIndexTests {
    private let sut = SpotlightEntryIndex(media: FileMediaStore(directory: URL(filePath: "/media")))
    private let tripID = UUID()

    @Test func mapsTheEntryToASearchableItem() {
        let entry = Entry(
            tripID: tripID,
            text: "Black ice cream!\nTasted of charcoal.",
            photoNames: ["a.jpg"],
            createdAt: Date(timeIntervalSince1970: 1_000),
            coordinate: Coordinate(latitude: 35.24, longitude: 139.02),
            placeName: "Hakone, Kanagawa",
            landmark: "Owakudani",
            tags: ["ice cream", "volcano", "amazed"]
        )

        let item = sut.item(for: SearchableEntry(entry: entry, tripName: "Japan"))
        let attributes = item.attributeSet

        #expect(item.uniqueIdentifier == entry.id.uuidString)
        #expect(item.domainIdentifier == tripID.uuidString)
        #expect(attributes.title == "Black ice cream!")
        #expect(attributes.textContent == "Black ice cream!\nTasted of charcoal.")
        #expect(attributes.keywords == ["ice cream", "volcano", "amazed", "Owakudani"])
        #expect(attributes.containerTitle == "Japan")
        #expect(attributes.namedLocation == "Owakudani, Hakone, Kanagawa")
        #expect(attributes.contentCreationDate == entry.createdAt)
        #expect(attributes.latitude == 35.24)
        #expect(attributes.thumbnailURL?.lastPathComponent == "a.jpg")
    }

    @Test func aVoiceNoteIsFoundByItsTranscript() {
        let entry = Entry(tripID: tripID, text: "", audioName: "v.m4a", transcript: "Ferry to Miyajima, windy.")

        let attributes = sut.item(for: SearchableEntry(entry: entry, tripName: nil)).attributeSet

        #expect(attributes.title == "Ferry to Miyajima, windy.")
        #expect(attributes.textContent == "Ferry to Miyajima, windy.")
    }

    @Test(arguments: [
        (Entry(tripID: UUID(), text: "", audioName: "v.m4a"), "Voice note"),
        (Entry(tripID: UUID(), text: "", photoNames: ["p.jpg"]), "Photo"),
        (Entry(tripID: UUID(), text: String(repeating: "a", count: 100)), String(repeating: "a", count: 79) + "…"),
    ] as [(Entry, String)])
    func titleFallsBackWhenThereAreNoWords(entry: Entry, title: String) {
        #expect(SpotlightEntryIndex.title(for: entry) == title)
    }
}
