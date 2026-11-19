import Domain

/// Temporary store until SwiftData persistence lands. Entries live only while the app runs.
public actor InMemoryEntryRepository: EntryRepository {
    private var entries: [Entry.ID: Entry] = [:]

    public init() {}

    public func save(_ entry: Entry) {
        entries[entry.id] = entry
    }
}
