import Foundation

extension Entry {
    /// The entry after indexing: the model's tags, then the mood as a tag, normalized and without duplicates.
    /// Tags already on the entry come first, so nothing the user added is lost.
    public func applying(_ index: EntryIndex) -> Entry {
        var updated = self
        let newTags = index.tags + [index.mood?.rawValue].compactMap { $0 }
        for tag in newTags.compactMap(Self.normalizedTag) where !updated.tags.contains(tag) {
            updated.tags.append(tag)
        }
        updated.indexingStatus = .done
        return updated
    }

    /// Deterministic cleanup the model can't be trusted with: lowercase, trimmed, no empty tags.
    /// "Narita" and "narita" must be the same tag, or search would treat them as different.
    static func normalizedTag(_ tag: String) -> String? {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
}
