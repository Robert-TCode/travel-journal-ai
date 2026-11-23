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

    @Test func neverOverwritesWhatIsAlreadyThere() {
        let entry = Entry(tripID: UUID(), text: "Fish market", placeName: "Bergen")

        #expect(entry.applying(EntryContext(placeName: "Oslo")).placeName == "Bergen")
    }
}
