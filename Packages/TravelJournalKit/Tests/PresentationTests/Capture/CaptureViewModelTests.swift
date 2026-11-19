import Domain
import Foundation
import Observation
import Testing
@testable import Presentation

@MainActor
@Suite("CaptureViewModel availability")
struct CaptureViewModelAvailabilityTests {
    @Test func startsWithUnknownAvailability() {
        let sut = makeSUT(availabilityService: MockAvailabilityService())

        #expect(sut.availability == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func followsAvailabilityChanges() async {
        let service = MockAvailabilityService()
        let sut = makeSUT(availabilityService: service)
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
        let sut = makeSUT(availabilityService: service)
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

@MainActor
@Suite("CaptureViewModel save")
struct CaptureViewModelSaveTests {
    @Test func savesTheNoteVerbatimAsAPendingEntry() async {
        let repository = MockEntryRepository()
        let sut = makeSUT(repository: repository)
        sut.noteText = "Walked 20k steps, my feet hurt."

        await sut.save()

        #expect(repository.savedEntries.map(\.text) == ["Walked 20k steps, my feet hurt."])
        #expect(repository.savedEntries.first?.indexingStatus == .pending)
        #expect(repository.savedEntries.first?.tags == [])
    }

    @Test func savesTheEntryIntoTheCurrentTrip() async {
        let tripID = UUID()
        let repository = MockEntryRepository()
        let sut = makeSUT(repository: repository, tripID: tripID)
        sut.noteText = "Black ice cream at Owakudani."

        await sut.save()

        #expect(repository.savedEntries.first?.tripID == tripID)
    }

    @Test func clearsTheNoteAndConfirmsAfterSaving() async {
        let sut = makeSUT()
        sut.noteText = "Black ice cream at Owakudani."

        await sut.save()

        #expect(sut.noteText.isEmpty)
        #expect(sut.didSave)
        #expect(!sut.isSaving)
    }

    @Test func hidesTheConfirmationWhenANewNoteStarts() async {
        let sut = makeSUT()
        sut.noteText = "First note"
        await sut.save()

        sut.noteText = "S"

        #expect(!sut.didSave)
    }

    @Test func keepsTheNoteWhenSavingFails() async {
        let sut = makeSUT(repository: MockEntryRepository(failing: true))
        sut.noteText = "Don't lose me."

        await sut.save()

        #expect(sut.noteText == "Don't lose me.")
        #expect(sut.saveFailed)
        #expect(!sut.didSave)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func doesNotSaveBlankNotes(_ text: String) async {
        let repository = MockEntryRepository()
        let sut = makeSUT(repository: repository)
        sut.noteText = text

        await sut.save()

        #expect(!sut.canSave)
        #expect(repository.savedEntries.isEmpty)
    }
}

@MainActor
private func makeSUT(
    availabilityService: any AIModelAvailabilityService = MockAvailabilityService(),
    repository: any EntryRepository = MockEntryRepository(),
    tripID: UUID = UUID()
) -> CaptureViewModel {
    CaptureViewModel(availabilityService: availabilityService, repository: repository, tripID: tripID)
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
