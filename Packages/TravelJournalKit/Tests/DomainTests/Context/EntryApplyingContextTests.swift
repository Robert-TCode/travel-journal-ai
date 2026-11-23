import Foundation
import Testing
import Domain

@Suite("Entry applying a context")
struct EntryApplyingContextTests {
    @Test func fillsMissingFields() {
        let context = EntryContext(coordinate: Coordinate(latitude: 1, longitude: 2), placeName: "Bergen", weather: .rainy, dayPhase: .night)

        let entry = Entry(tripID: UUID(), text: "Fish market").applying(context)

        #expect(entry.coordinate == context.coordinate)
        #expect(entry.placeName == "Bergen")
        #expect(entry.weather == .rainy)
        #expect(entry.dayPhase == .night)
    }

    @Test func fillsNearbyPlacesOnlyWhenThereAreNone() {
        let context = EntryContext(nearbyPlaces: ["Bryggen", "Fish Market"])

        #expect(Entry(tripID: UUID(), text: "").applying(context).nearbyPlaces == ["Bryggen", "Fish Market"])
        #expect(Entry(tripID: UUID(), text: "", nearbyPlaces: ["Fløyen"]).applying(context).nearbyPlaces == ["Fløyen"])
    }

    @Test func neverOverwritesWhatIsAlreadyThere() {
        let entry = Entry(tripID: UUID(), text: "Fish market", placeName: "Bergen")

        #expect(entry.applying(EntryContext(placeName: "Oslo")).placeName == "Bergen")
    }
}
