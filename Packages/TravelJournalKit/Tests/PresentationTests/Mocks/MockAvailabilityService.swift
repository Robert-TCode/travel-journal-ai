import Domain
import Synchronization

final class MockAvailabilityService: AIModelAvailabilityService {
    private let stream: AsyncStream<AIModelAvailability>
    private let continuation: AsyncStream<AIModelAvailability>.Continuation
    private let terminated = Mutex(false)

    init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    var isTerminated: Bool { terminated.withLock { $0 } }

    func send(_ availability: AIModelAvailability) {
        continuation.yield(availability)
    }

    /// Single consumer only: every call returns the same stream, which is enough for one view model under test.
    func availabilityUpdates() -> AsyncStream<AIModelAvailability> {
        continuation.onTermination = { [weak self] _ in
            self?.terminated.withLock { $0 = true }
        }
        return stream
    }
}
