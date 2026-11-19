import Domain
import Synchronization

struct MockRepositoryError: Error {}

/// Records saved entries; can be told to fail.
final class MockEntryRepository: EntryRepository {
    private let shouldFail: Bool
    private let saved = Mutex<[Entry]>([])

    init(failing shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var savedEntries: [Entry] { saved.withLock { $0 } }

    func save(_ entry: Entry) async throws {
        if shouldFail { throw MockRepositoryError() }
        saved.withLock { $0.append(entry) }
    }
}
