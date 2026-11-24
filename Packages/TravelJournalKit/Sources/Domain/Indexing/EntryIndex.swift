/// What indexing understood about an entry. `mood` is nil when the entry has no clear mood; there is no "neutral".
/// `landmark` is nil when no nearby place was offered or none fits.
public struct EntryIndex: Sendable, Equatable {
    public let tags: [String]
    public let mood: Mood?
    public let landmark: String?
    public let categories: [EntryCategory]

    public init(tags: [String], mood: Mood?, landmark: String? = nil, categories: [EntryCategory] = []) {
        self.tags = tags
        self.mood = mood
        self.landmark = landmark
        self.categories = categories
    }
}
