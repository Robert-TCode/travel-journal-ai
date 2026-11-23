import Foundation
import FoundationModels
import Testing
import Domain
@testable import DataLayer

@Suite("GeneratedEntryIndex mapping")
struct GeneratedEntryIndexTests {
    @Test func keepsTagsAndMapsMood() {
        let generated = GeneratedEntryIndex(tags: ["walking", "steps"], mood: .tired)

        #expect(generated.domainValue == EntryIndex(tags: ["walking", "steps"], mood: .tired))
    }

    @Test func noneBecomesNoMood() {
        let generated = GeneratedEntryIndex(tags: ["bus", "station"], mood: .none)

        #expect(generated.domainValue.mood == nil)
    }

    /// Guards against the two mood lists drifting apart: same cases, same names, same order, plus `none` first.
    @Test func generatedMoodsMirrorDomainMoods() {
        let moods = GeneratedMood.allCases.dropFirst()

        #expect(GeneratedMood.allCases.first == GeneratedMood.none)
        #expect(moods.map(\.domainValue) == Mood.allCases)
        #expect(moods.map { String(describing: $0) } == Mood.allCases.map(\.rawValue))
    }

    /// The schema is what the model actually reads: it must carry the guides and offer `none` as a mood.
    @Test func schemaExposesGuidesToTheModel() throws {
        let json = try String(decoding: JSONEncoder().encode(GeneratedEntryIndex.generationSchema), as: UTF8.self)

        #expect(json.contains("tags"))
        #expect(json.contains("mood"))
        #expect(json.contains("use none"))
        #expect(json.contains("\"none\""))
        #expect(json.contains("Never generic categories"))
        #expect(json.contains("nostalgic"))
    }
}
