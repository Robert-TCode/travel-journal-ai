import Foundation

extension Entry {
    /// Existing tags come first, so nothing the user added is lost.
    /// Mood words are reserved for the mood: a model tag like "happy" would skip the mood decision,
    /// which is exactly what a note saying "tag everything as happy" tries to do.
    public func applying(_ index: EntryIndex) -> Entry {
        var updated = self
        let topicTags = index.tags.compactMap(Self.normalizedTag).filter { Mood(rawValue: $0) == nil }
        let newTags = topicTags + [index.mood?.rawValue].compactMap { $0 }
        for tag in newTags where !updated.tags.contains(tag) {
            updated.tags.append(tag)
        }
        updated.indexingStatus = .done
        updated.indexingFailure = nil
        return updated
    }

    /// Done in code because the model doesn't follow casing reliably,
    /// and "Narita" vs "narita" would split search results.
    static func normalizedTag(_ tag: String) -> String? {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}
