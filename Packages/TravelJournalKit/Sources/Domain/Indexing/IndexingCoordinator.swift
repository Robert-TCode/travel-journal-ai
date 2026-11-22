/// Indexes saved entries one at a time, in the order they were saved, and stores the result.
///
/// Lives at app level (created in the composition root), so indexing outlives the screen that saved the entry.
/// Serial on purpose: the on-device model is a single shared resource, so parallel requests gain no speed
/// and only add memory pressure.
public actor IndexingCoordinator: IndexingQueue {
    private let indexer: any EntryIndexer
    private let repository: any EntryRepository
    private var queue: [Entry] = []
    private var drainTask: Task<Void, Never>?

    public init(indexer: any EntryIndexer, repository: any EntryRepository) {
        self.indexer = indexer
        self.repository = repository
    }

    public func enqueue(_ entry: Entry) {
        queue.append(entry)
        if drainTask == nil {
            drainTask = Task { await drain() }
        }
    }

    /// Returns once the queue is empty. Used by tests; the app never needs to wait.
    public func waitUntilIdle() async {
        while let drainTask {
            await drainTask.value
        }
    }

    private func drain() async {
        while !queue.isEmpty {
            let entry = queue.removeFirst()
            await index(entry)
        }
        drainTask = nil
    }

    private func index(_ entry: Entry) async {
        var updated = entry
        do {
            updated = entry.applying(try await indexer.index(entry))
        } catch {
            updated.indexingStatus = .failed
        }
        // The original entry is already stored; if this write fails, it simply stays pending.
        try? await repository.save(updated)
    }
}
