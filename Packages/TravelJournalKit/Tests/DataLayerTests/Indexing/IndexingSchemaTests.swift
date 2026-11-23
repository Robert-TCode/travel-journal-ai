import Domain
import Foundation
import FoundationModels
import Testing
@testable import DataLayer

@Suite("Indexing schema")
struct IndexingSchemaTests {
    /// The schema is what the model actually reads, so these check its JSON, not our Swift.
    private func json(nearbyPlaces: [String]) throws -> String {
        String(decoding: try JSONEncoder().encode(try IndexingSchema.schema(nearbyPlaces: nearbyPlaces)), as: UTF8.self)
    }

    @Test func offersTheNearbyPlacesAndNoneAsTheOnlyLandmarks() throws {
        let json = try json(nearbyPlaces: ["Owakudani", "Hakone Ropeway"])

        #expect(json.contains("\"Owakudani\""))
        #expect(json.contains("\"Hakone Ropeway\""))
        #expect(json.contains("clearly about"))
    }

    @Test func withoutNearbyPlacesThereIsNoLandmarkToChoose() throws {
        #expect(try !json(nearbyPlaces: []).contains("landmark"))
    }

    @Test func carriesTheTagAndMoodGuides() throws {
        let json = try json(nearbyPlaces: [])

        #expect(json.contains("Never generic categories"))
        #expect(json.contains("use none"))
        #expect(json.contains("nostalgic"))
    }

    @Test func readsTagsMoodAndLandmark() throws {
        let content = GeneratedContent(properties: [
            "landmark": "Owakudani",
            "tags": ["black ice cream", "volcano"],
            "mood": GeneratedMood.amazed,
        ])

        let index = try IndexingSchema.index(from: content)

        #expect(index == EntryIndex(tags: ["black ice cream", "volcano"], mood: .amazed, landmark: "Owakudani"))
    }

    @Test func noneMeansNoLandmarkAndNoMood() throws {
        let content = GeneratedContent(properties: ["landmark": "none", "tags": ["bus"], "mood": GeneratedMood.none])

        let index = try IndexingSchema.index(from: content)

        #expect(index.landmark == nil)
        #expect(index.mood == nil)
    }

    @Test func aResponseWithoutLandmarkStillReads() throws {
        let content = GeneratedContent(properties: ["tags": ["bus"], "mood": GeneratedMood.none])

        #expect(try IndexingSchema.index(from: content).landmark == nil)
    }

    /// Guards against the two mood lists drifting apart: same cases, same names, same order, plus `none` first.
    @Test func generatedMoodsMirrorDomainMoods() {
        let moods = GeneratedMood.allCases.dropFirst()

        #expect(GeneratedMood.allCases.first == GeneratedMood.none)
        #expect(moods.map(\.domainValue) == Mood.allCases)
        #expect(moods.map { String(describing: $0) } == Mood.allCases.map(\.rawValue))
    }
}
