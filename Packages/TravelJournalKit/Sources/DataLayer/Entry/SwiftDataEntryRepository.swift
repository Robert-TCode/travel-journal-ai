import Domain
import Foundation
import SwiftData

/// All writes go through this actor, so it notifies observers itself
/// instead of watching the store for changes made elsewhere.
public actor SwiftDataEntryRepository: EntryRepository {
    private let context: ModelContext
    private var observers: [UUID: (tripID: UUID, continuation: AsyncStream<[Entry]>.Continuation)] = [:]

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    public static func onDisk() throws -> SwiftDataEntryRepository {
        SwiftDataEntryRepository(container: try ModelContainer(for: EntryRecord.self))
    }

    static func inMemory() throws -> SwiftDataEntryRepository {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return SwiftDataEntryRepository(container: try ModelContainer(for: EntryRecord.self, configurations: configuration))
    }

    public func save(_ entry: Entry) throws {
        let id = entry.id
        var descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first {
            record.update(from: entry)
        } else {
            context.insert(EntryRecord(entry))
        }
        try context.save()

        let snapshot = (try? entries(in: entry.tripID)) ?? []
        for observer in observers.values where observer.tripID == entry.tripID {
            observer.continuation.yield(snapshot)
        }
    }

    public func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        // Only the latest list matters: a slow consumer skips intermediate snapshots instead of queueing them.
        let (stream, continuation) = AsyncStream.makeStream(of: [Entry].self, bufferingPolicy: .bufferingNewest(1))
        let observerID = UUID()
        observers[observerID] = (tripID, continuation)
        continuation.yield((try? entries(in: tripID)) ?? [])
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(observerID) }
        }
        return stream
    }

    public func pendingEntries() throws -> [Entry] {
        let pending = Entry.IndexingStatus.pending.rawValue
        let descriptor = FetchDescriptor<EntryRecord>(
            predicate: #Predicate { $0.indexingStatus == pending },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).map(\.entry)
    }

    private func entries(in tripID: UUID) throws -> [Entry] {
        let descriptor = FetchDescriptor<EntryRecord>(
            predicate: #Predicate { $0.tripID == tripID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.entry)
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }
}
