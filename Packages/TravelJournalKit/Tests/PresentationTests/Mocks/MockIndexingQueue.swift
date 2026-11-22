import Domain
import Synchronization

/// Records what Capture handed off for indexing.
final class MockIndexingQueue: IndexingQueue {
    private let enqueued = Mutex<[Entry]>([])

    var enqueuedEntries: [Entry] { enqueued.withLock { $0 } }

    func enqueue(_ entry: Entry) async {
        enqueued.withLock { $0.append(entry) }
    }
}
