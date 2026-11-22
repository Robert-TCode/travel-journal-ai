import Domain
import Foundation
import Synchronization

struct MockRepositoryError: Error {}

final class MockEntryRepository: EntryRepository {
    private let shouldFail: Bool
    private let saved = Mutex<[Entry]>([])
    private let stream: AsyncStream<[Entry]>
    private let continuation: AsyncStream<[Entry]>.Continuation

    init(failing shouldFail: Bool = false) {
        self.shouldFail = shouldFail
        (stream, continuation) = AsyncStream.makeStream()
    }

    func send(_ entries: [Entry]) {
        continuation.yield(entries)
    }

    func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        stream
    }

    func allEntryUpdates() -> AsyncStream<[Entry]> {
        stream
    }

    func pendingEntries() -> [Entry] { [] }

    var savedEntries: [Entry] { saved.withLock { $0 } }

    func save(_ entry: Entry) async throws {
        if shouldFail { throw MockRepositoryError() }
        saved.withLock { $0.append(entry) }
    }
}
