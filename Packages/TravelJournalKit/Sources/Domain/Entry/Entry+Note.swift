import Foundation

extension Entry {
    /// Whether the writer said anything, typed or spoken. Mood is the writer's feeling, so without words
    /// there is none to find: in the photo eval the model read "relaxed" into every garden photo.
    public var hasWrittenNote: Bool {
        [text, transcript ?? ""].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
