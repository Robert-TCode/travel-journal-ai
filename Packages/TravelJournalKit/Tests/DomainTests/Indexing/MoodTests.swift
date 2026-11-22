import Testing
import Domain

@Suite("Mood")
struct MoodTests {
    @Test func vocabularyIsFixedAndHasNoNeutral() {
        #expect(Mood.allCases.map(\.rawValue) == ["happy", "excited", "relaxed", "amazed", "tired", "frustrated", "nostalgic"])
    }
}
