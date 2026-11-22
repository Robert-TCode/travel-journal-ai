extension Entry {
    /// The entry after indexing: the model's tags, then the mood as a tag, without duplicates.
    /// Tags already on the entry come first, so nothing the user added is lost.
    public func applying(_ index: EntryIndex) -> Entry {
        var updated = self
        let newTags = index.tags + [index.mood?.rawValue].compactMap { $0 }
        for tag in newTags where !updated.tags.contains(tag) {
            updated.tags.append(tag)
        }
        updated.indexingStatus = .done
        return updated
    }
}
