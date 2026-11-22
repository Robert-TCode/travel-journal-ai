import Foundation

extension Entry {
    /// Existing tags come first, so nothing the user added is lost.
    public func applying(_ index: EntryIndex) -> Entry {
        var updated = self
        let newTags = index.tags + [index.mood?.rawValue].compactMap { $0 }
        for tag in newTags.compactMap(Self.normalizedTag) where !updated.tags.contains(tag) {
            updated.tags.append(tag)
        }
        updated.indexingStatus = .done
        return updated
    }

    /// Done in code because the model doesn't follow casing reliably,
    /// and "Narita" vs "narita" would split search results.
    static func normalizedTag(_ tag: String) -> String? {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}
