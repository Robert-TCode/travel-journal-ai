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

    @Test func noMoodStaysNoMood() {
        let generated = GeneratedEntryIndex(tags: ["bus", "station"], mood: nil)

        #expect(generated.domainValue.mood == nil)
    }

    /// Guards against the two mood lists drifting apart: same cases, same names, same order.
    @Test func generatedMoodsMirrorDomainMoods() {
        #expect(GeneratedMood.allCases.map(\.domainValue) == Mood.allCases)
        #expect(GeneratedMood.allCases.map { String(describing: $0) } == Mood.allCases.map(\.rawValue))
    }

    /// The schema is what the model actually reads: it must carry the guides and allow an empty mood.
    @Test func schemaExposesGuidesToTheModel() throws {
        let json = try String(decoding: JSONEncoder().encode(GeneratedEntryIndex.generationSchema), as: UTF8.self)

        #expect(json.contains("tags"))
        #expect(json.contains("mood"))
        #expect(json.contains("never guess"))
        #expect(json.contains("nostalgic"))
    }
}
