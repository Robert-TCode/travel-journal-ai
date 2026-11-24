import Domain
import Foundation

struct StubMemorySearcher: MemorySearcher {
    var result: Result<[UUID], any Error> = .success([])

    func search(_ question: String) async throws -> [UUID] {
        try result.get()
    }
}

/// Holds each search until the test releases it, so tests can act while a search is in flight.
actor GatedMemorySearcher: MemorySearcher {
    private var waiting: [CheckedContinuation<[UUID], any Error>] = []

    var pendingCount: Int { waiting.count }

    func search(_ question: String) async throws -> [UUID] {
        try await withCheckedThrowingContinuation { waiting.append($0) }
    }

    /// Answers the oldest waiting search.
    func release(with result: Result<[UUID], any Error>) {
        waiting.removeFirst().resume(with: result)
    }
}
