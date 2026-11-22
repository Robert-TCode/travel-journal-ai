import Domain
import Foundation

/// Temporary store until SwiftData persistence lands. Entries live only while the app runs.
public actor InMemoryEntryRepository: EntryRepository {
    private var entries: [Entry.ID: Entry] = [:]
    private var observers: [UUID: (tripID: UUID, continuation: AsyncStream<[Entry]>.Continuation)] = [:]

    public init() {}

    public func save(_ entry: Entry) {
        entries[entry.id] = entry
        let snapshot = snapshot(of: entry.tripID)
        for observer in observers.values where observer.tripID == entry.tripID {
            observer.continuation.yield(snapshot)
        }
    }

    public func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        // Only the latest list matters: a slow consumer skips intermediate snapshots instead of queueing them.
        let (stream, continuation) = AsyncStream.makeStream(of: [Entry].self, bufferingPolicy: .bufferingNewest(1))
        let observerID = UUID()
        observers[observerID] = (tripID, continuation)
        continuation.yield(snapshot(of: tripID))
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(observerID) }
        }
        return stream
    }

    private func snapshot(of tripID: UUID) -> [Entry] {
        entries.values
            .filter { $0.tripID == tripID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }
}
