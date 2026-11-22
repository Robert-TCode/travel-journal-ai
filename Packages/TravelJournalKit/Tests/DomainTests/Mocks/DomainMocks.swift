import Domain
import Foundation
import Synchronization

struct MockIndexerError: Error {}

/// Returns a fixed index (or fails) and records the order and overlap of calls.
final class MockEntryIndexer: EntryIndexer {
    private let result: Result<EntryIndex, MockIndexerError>
    private let state = Mutex<(order: [String], inFlight: Int, maxInFlight: Int)>(([], 0, 0))

    init(returning result: Result<EntryIndex, MockIndexerError>) {
        self.result = result
    }

    var indexedTexts: [String] { state.withLock { $0.order } }
    var maxConcurrentCalls: Int { state.withLock { $0.maxInFlight } }

    func index(_ entry: Entry) async throws -> EntryIndex {
        state.withLock {
            $0.order.append(entry.text)
            $0.inFlight += 1
            $0.maxInFlight = max($0.maxInFlight, $0.inFlight)
        }
        // Give a parallel caller every chance to overlap, so a non-serial coordinator would be caught.
        for _ in 0..<5 { await Task.yield() }
        state.withLock { $0.inFlight -= 1 }
        return try result.get()
    }
}

/// Keeps the last saved version of each entry, like a real store would.
final class SpyEntryRepository: EntryRepository {
    private let stored = Mutex<[Entry]>([])

    var entries: [Entry] { stored.withLock { $0 } }

    func save(_ entry: Entry) async throws {
        stored.withLock { entries in
            entries.removeAll { $0.id == entry.id }
            entries.append(entry)
        }
    }

    func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        AsyncStream { $0.finish() }
    }
}
