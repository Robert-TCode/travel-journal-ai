/// What indexing understood about an entry. `mood` is nil when the entry has no clear mood; there is no "neutral".
public struct EntryIndex: Sendable, Equatable {
    public let tags: [String]
    public let mood: Mood?

    public init(tags: [String], mood: Mood?) {
        self.tags = tags
        self.mood = mood
    }
}
