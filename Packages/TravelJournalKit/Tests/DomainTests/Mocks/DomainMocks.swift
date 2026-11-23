import Domain
import Foundation
import Synchronization

struct MockIndexerError: Error {}

final class MockEntryIndexer: EntryIndexer {
    private let result: Result<EntryIndex, any Error>
    private let state = Mutex<(order: [String], inFlight: Int, maxInFlight: Int)>(([], 0, 0))
    private let received = Mutex<[Entry]>([])

    init(returning result: Result<EntryIndex, any Error>) {
        self.result = result
    }

    var indexedTexts: [String] { state.withLock { $0.order } }
    var maxConcurrentCalls: Int { state.withLock { $0.maxInFlight } }

    var receivedEntries: [Entry] { received.withLock { $0 } }

    func index(_ entry: Entry) async throws -> EntryIndex {
        received.withLock { $0.append(entry) }
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

    func allEntryUpdates() -> AsyncStream<[Entry]> {
        AsyncStream { $0.finish() }
    }

    func pendingEntries() -> [Entry] {
        entries.filter { $0.indexingStatus == .pending }.sorted { $0.createdAt < $1.createdAt }
    }
}

final class StubContextProvider: EntryContextProvider {
    private let context: EntryContext
    private let calls = Mutex(0)

    init(context: EntryContext = .empty) {
        self.context = context
    }

    var callCount: Int { calls.withLock { $0 } }

    func currentContext() async -> EntryContext {
        calls.withLock { $0 += 1 }
        return context
    }
}

struct StubTranscriber: Transcriber {
    var result: Result<String, MockIndexerError> = .success("")

    func transcribe(audioNamed name: String) async throws -> String {
        try result.get()
    }
}
