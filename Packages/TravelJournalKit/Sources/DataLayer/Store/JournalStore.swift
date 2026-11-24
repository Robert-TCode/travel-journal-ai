import SwiftData

/// Entries, trips and stories share one store, so a single file holds the whole journal.
public struct JournalStore: Sendable {
    public let entries: SwiftDataEntryRepository
    public let trips: SwiftDataTripRepository
    public let stories: SwiftDataTripStoryRepository

    public static func onDisk() throws -> JournalStore {
        try JournalStore(container: ModelContainer(for: EntryRecord.self, TripRecord.self, TripStoryRecord.self))
    }

    static func inMemory() throws -> JournalStore {
        try JournalStore(container: ModelContainer(
            for: EntryRecord.self, TripRecord.self, TripStoryRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))
    }

    init(container: ModelContainer) {
        entries = SwiftDataEntryRepository(container: container)
        trips = SwiftDataTripRepository(container: container)
        stories = SwiftDataTripStoryRepository(container: container)
    }
}
