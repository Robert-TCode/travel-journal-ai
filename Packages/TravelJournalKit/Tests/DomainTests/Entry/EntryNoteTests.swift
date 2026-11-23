import Foundation
import Testing
import Domain

@Suite("Entry has a written note")
struct EntryNoteTests {
    @Test func typedTextCounts() {
        #expect(Entry(tripID: UUID(), text: "Best ramen ever").hasWrittenNote)
    }

    @Test func aVoiceNoteTranscriptCounts() {
        #expect(Entry(tripID: UUID(), text: "", audioName: "a.m4a", transcript: "So tired today").hasWrittenNote)
    }

    @Test func aPhotoAloneHasNoNote() {
        #expect(!Entry(tripID: UUID(), text: "", photoNames: ["garden.jpg"]).hasWrittenNote)
    }

    @Test func whitespaceIsNotANote() {
        #expect(!Entry(tripID: UUID(), text: "  \n ", transcript: " ").hasWrittenNote)
    }
}
