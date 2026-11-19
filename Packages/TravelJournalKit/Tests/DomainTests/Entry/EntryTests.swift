import Foundation
import Testing
import Domain

@Suite("Entry")
struct EntryTests {
    @Test func aNewEntryWaitsForIndexingWithNoMetadataYet() {
        let entry = Entry(tripID: UUID(), text: "Walked 20k steps.")

        #expect(entry.indexingStatus == .pending)
        #expect(entry.tags.isEmpty)
        #expect(entry.coordinate == nil)
        #expect(entry.placeName == nil)
        #expect(entry.weather == nil)
        #expect(entry.isDaytime == nil)
    }

    @Test func keepsTheTextVerbatim() {
        let text = "  Black ice cream 🍦 at Owakudani!!  "

        #expect(Entry(tripID: UUID(), text: text).text == text)
    }

    @Test func weatherRawValuesAreStableTags() {
        #expect(WeatherCondition.allCases.map(\.rawValue) == ["sunny", "cloudy", "rainy", "snowy", "windy", "foggy", "stormy"])
    }
}
