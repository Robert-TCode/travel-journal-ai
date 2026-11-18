import Domain
import Observation
import Testing
@testable import Presentation

@MainActor
@Suite("CaptureViewModel availability")
struct CaptureViewModelTests {
    @Test func startsWithUnknownAvailability() {
        let sut = CaptureViewModel(availabilityService: MockAvailabilityService())

        #expect(sut.availability == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func followsAvailabilityChanges() async {
        let service = MockAvailabilityService()
        let sut = CaptureViewModel(availabilityService: service)
        var changes = AvailabilityChanges(of: sut)
        #expect(await changes.next() == nil)

        let observing = Task { await sut.observeAvailability() }
        defer { observing.cancel() }

        service.send(.unavailable(reason: .notReadyYet))
        #expect(await changes.next() == .unavailable(reason: .notReadyYet))

        service.send(.available)
        #expect(await changes.next() == .available)
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsListeningWhenObservationIsCancelled() async {
        let service = MockAvailabilityService()
        let sut = CaptureViewModel(availabilityService: service)
        var changes = AvailabilityChanges(of: sut)
        _ = await changes.next()

        let observing = Task { await sut.observeAvailability() }
        service.send(.available)
        _ = await changes.next()
        #expect(!service.isTerminated)

        observing.cancel()
        await observing.value

        #expect(service.isTerminated)
    }
}

/// Waits for the view model's `availability` to change instead of sleeping.
/// `Observations` emits the current value first, then each new value.
private struct AvailabilityChanges {
    private var iterator: Observations<AIModelAvailability?, Never>.Iterator

    @MainActor
    init(of viewModel: CaptureViewModel) {
        iterator = Observations { viewModel.availability }.makeAsyncIterator()
    }

    /// Runs on the caller's actor (`#isolation`), so the iterator never leaves the test's actor.
    mutating func next(isolation: isolated (any Actor)? = #isolation) async -> AIModelAvailability? {
        await iterator.next(isolation: isolation) ?? nil
    }
}
