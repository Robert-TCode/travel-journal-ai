import Domain
import Foundation
import SwiftData

/// All writes go through this actor, so it notifies observers itself
/// instead of watching the store for changes made elsewhere.
public actor SwiftDataEntryRepository: EntryRepository {
    private let context: ModelContext
    /// A nil trip ID observes every trip.
    private var observers: [UUID: (tripID: UUID?, continuation: AsyncStream<[Entry]>.Continuation)] = [:]

    init(container: ModelContainer) {
        context = ModelContext(container)
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

        for observer in observers.values where observer.tripID == nil || observer.tripID == entry.tripID {
            observer.continuation.yield((try? entries(in: observer.tripID)) ?? [])
        }
    }

    public func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        updates(tripID: tripID)
    }

    public func allEntryUpdates() -> AsyncStream<[Entry]> {
        updates(tripID: nil)
    }

    private func updates(tripID: UUID?) -> AsyncStream<[Entry]> {
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

    private func entries(in tripID: UUID?) throws -> [Entry] {
        var descriptor = FetchDescriptor<EntryRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let tripID {
            descriptor.predicate = #Predicate { $0.tripID == tripID }
        }
        return try context.fetch(descriptor).map(\.entry)
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }
}
