import Domain
import Foundation

struct StubMemorySearcher: MemorySearcher {
    var result: Result<[UUID], any Error> = .success([])

    func search(_ question: String) async throws -> [UUID] {
        try result.get()
    }
}
