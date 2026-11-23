import Domain
import Foundation
import Observation
import Testing
@testable import Presentation

@MainActor
@Suite("CaptureViewModel availability")
struct CaptureViewModelAvailabilityTests {
    @Test func startsWithUnknownAvailability() {
        let sut = makeSUT()

        #expect(sut.availability == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func followsAvailabilityChanges() async {
        let service = MockAvailabilityService()
        let sut = makeSUT(availability: service)
        var changes = Changes { sut.availability }
        #expect(await changes.next() == .some(nil))

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
        let sut = makeSUT(availability: service)
        var changes = Changes { sut.availability }
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
@Suite("CaptureViewModel trips")
struct CaptureViewModelTripTests {
    @Test(.timeLimit(.minutes(1)))
    func knowsWhenThereIsNoOngoingTrip() async {
        let sut = makeSUT(trips: FakeTripRepository(trips: [Trip(name: "Norway", endedAt: .now)]))
        var loaded = Changes { sut.hasLoadedTrips }
        _ = await loaded.next()

        let observing = Task { await sut.observeTrips() }
        defer { observing.cancel() }

        #expect(await loaded.next() == true)
        #expect(sut.ongoingTrip == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func startingATripMakesItTheOngoingOne() async {
        let trips = FakeTripRepository()
        let sut = makeSUT(trips: trips)
        var ongoing = Changes { sut.ongoingTrip }
        _ = await ongoing.next()
        let observing = Task { await sut.observeTrips() }
        defer { observing.cancel() }

        sut.tripNameDraft = "  Japan "
        await sut.startTrip()

        #expect(await ongoing.next()??.name == "Japan")
        #expect(sut.tripNameDraft.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func endingTheTripLeavesNoOngoingTrip() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip()
        defer { observing.cancel() }
        var ongoing = Changes { sut.ongoingTrip }
        _ = await ongoing.next()

        await sut.endOngoingTrip()

        #expect(await ongoing.next() == .some(nil))
    }

    @Test func suggestsTheCityAsTripName() async {
        let sut = makeSUT(context: StubContextProvider(context: EntryContext(placeName: "Hakone, Kanagawa")))

        await sut.suggestTripName()

        #expect(sut.tripNameDraft == "Hakone")
    }

    @Test func neverOverwritesATypedTripName() async {
        let sut = makeSUT(context: StubContextProvider(context: EntryContext(placeName: "Hakone, Kanagawa")))
        sut.tripNameDraft = "Japan"

        await sut.suggestTripName()

        #expect(sut.tripNameDraft == "Japan")
    }

    @Test func countsTripDaysFromOne() {
        let sut = makeSUT()
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 22))!
        let trip = Trip(name: "Japan", startedAt: start)

        #expect(sut.dayNumber(of: trip, today: start, calendar: calendar) == 1)
        #expect(sut.dayNumber(of: trip, today: calendar.date(byAdding: .hour, value: 3, to: start)!, calendar: calendar) == 2)
    }
}

@MainActor
@Suite("CaptureViewModel save")
struct CaptureViewModelSaveTests {
    @Test(.timeLimit(.minutes(1)))
    func savesTheNoteVerbatimAsAPendingEntryOfTheOngoingTrip() async {
        let repository = MockEntryRepository()
        let (sut, trip, observing) = await makeSUTWithOngoingTrip(entries: repository)
        defer { observing.cancel() }
        sut.noteText = "Walked 20k steps, my feet hurt."

        await sut.save()

        #expect(repository.savedEntries.map(\.text) == ["Walked 20k steps, my feet hurt."])
        #expect(repository.savedEntries.first?.tripID == trip.id)
        #expect(repository.savedEntries.first?.indexingStatus == .pending)
    }

    @Test func cannotSaveWithoutAnOngoingTrip() async {
        let repository = MockEntryRepository()
        let sut = makeSUT(entries: repository)
        sut.noteText = "Nowhere to go"

        await sut.save()

        #expect(!sut.canSave)
        #expect(repository.savedEntries.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func clearsTheNoteAndConfirmsAfterSaving() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip()
        defer { observing.cancel() }
        sut.noteText = "Black ice cream at Owakudani."

        await sut.save()

        #expect(sut.noteText.isEmpty)
        #expect(sut.didSave)
        #expect(!sut.isSaving)
    }

    @Test(.timeLimit(.minutes(1)))
    func hidesTheConfirmationWhenANewNoteStarts() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip()
        defer { observing.cancel() }
        sut.noteText = "First note"
        await sut.save()

        sut.noteText = "S"

        #expect(!sut.didSave)
    }

    @Test(.timeLimit(.minutes(1)))
    func handsTheSavedEntryToIndexing() async {
        let repository = MockEntryRepository()
        let queue = MockIndexingQueue()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository, indexingQueue: queue)
        defer { observing.cancel() }
        sut.noteText = "Black ice cream at Owakudani."

        await sut.save()

        #expect(queue.enqueuedEntries.map(\.id) == repository.savedEntries.map(\.id))
    }

    @Test(.timeLimit(.minutes(1)))
    func keepsTheNoteAndSkipsIndexingWhenSavingFails() async {
        let queue = MockIndexingQueue()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: MockEntryRepository(failing: true), indexingQueue: queue)
        defer { observing.cancel() }
        sut.noteText = "Don't lose me."

        await sut.save()

        #expect(sut.noteText == "Don't lose me.")
        #expect(sut.saveFailed)
        #expect(queue.enqueuedEntries.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)), arguments: ["", "   ", "\n\t"])
    func doesNotSaveBlankNotes(_ text: String) async {
        let repository = MockEntryRepository()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository)
        defer { observing.cancel() }
        sut.noteText = text

        await sut.save()

        #expect(!sut.canSave)
        #expect(repository.savedEntries.isEmpty)
    }
}

@MainActor
@Suite("CaptureViewModel photos")
struct CaptureViewModelPhotoTests {
    @Test(.timeLimit(.minutes(1)))
    func aPhotoAloneCanBeSaved() async {
        let repository = MockEntryRepository()
        let media = MockMediaStore()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository, media: media)
        defer { observing.cancel() }

        await sut.addPhoto(Data("photo".utf8))
        #expect(sut.canSave)
        await sut.save()

        #expect(media.storedPhotos == [Data("photo".utf8)])
        #expect(repository.savedEntries.first?.photoNames == ["photo-1.jpg"])
        #expect(repository.savedEntries.first?.text == "")
        #expect(sut.pendingPhotos.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func keepsPhotosInOrderWithTheCaption() async {
        let repository = MockEntryRepository()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository)
        defer { observing.cancel() }

        await sut.addPhoto(Data("first".utf8))
        await sut.addPhoto(Data("second".utf8))
        sut.noteText = "Black ice cream"
        await sut.save()

        #expect(repository.savedEntries.first?.photoNames == ["photo-1.jpg", "photo-2.jpg"])
        #expect(repository.savedEntries.first?.text == "Black ice cream")
    }

    @Test(.timeLimit(.minutes(1)))
    func removedPhotosAreNotSaved() async {
        let media = MockMediaStore()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(media: media)
        defer { observing.cancel() }
        await sut.addPhoto(Data("keep".utf8))
        await sut.addPhoto(Data("drop".utf8))

        sut.removePhoto(sut.pendingPhotos[1])
        await sut.save()

        #expect(media.storedPhotos == [Data("keep".utf8)])
    }

    @Test(.timeLimit(.minutes(1)))
    func keepsThePhotosWhenStoringFails() async {
        let repository = MockEntryRepository()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository, media: MockMediaStore(failing: true))
        defer { observing.cancel() }
        await sut.addPhoto(Data("photo".utf8))

        await sut.save()

        #expect(sut.saveFailed)
        #expect(sut.pendingPhotos.count == 1)
        #expect(repository.savedEntries.isEmpty)
    }

    /// The photos stay in the composer for a retry, so the copies stored by the failed attempt would never be used.
    @Test(.timeLimit(.minutes(1)))
    func photosStoredForAnEntryThatFailedToSaveAreDeleted() async {
        let media = MockMediaStore()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: MockEntryRepository(failing: true), media: media)
        defer { observing.cancel() }
        await sut.addPhoto(Data("one".utf8))
        await sut.addPhoto(Data("two".utf8))

        await sut.save()

        #expect(sut.saveFailed)
        #expect(media.deletedPhotos == ["photo-1.jpg", "photo-2.jpg"])
        #expect(sut.pendingPhotos.count == 2)
    }
}

@MainActor
@Suite("CaptureViewModel voice notes")
struct CaptureViewModelVoiceTests {
    @Test(.timeLimit(.minutes(1)))
    func aVoiceNoteIsSavedAsItsOwnEntryAndIndexed() async {
        let repository = MockEntryRepository()
        let queue = MockIndexingQueue()
        let (sut, trip, observing) = await makeSUTWithOngoingTrip(entries: repository, indexingQueue: queue)
        defer { observing.cancel() }
        sut.noteText = "A draft that stays in the editor"

        await sut.startRecording()
        #expect(sut.recordingStartedAt != nil)
        await sut.finishRecording()

        let saved = repository.savedEntries.first
        #expect(saved?.audioName == "voice.m4a")
        #expect(saved?.text == "")
        #expect(saved?.tripID == trip.id)
        #expect(saved?.transcript == nil)
        #expect(queue.enqueuedEntries.map(\.id) == [saved?.id])
        #expect(sut.noteText == "A draft that stays in the editor")
        #expect(sut.recordingStartedAt == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func anEmptyRecordingSavesNothing() async {
        let repository = MockEntryRepository()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository, recorder: MockVoiceRecorder(recording: nil))
        defer { observing.cancel() }

        await sut.startRecording()
        await sut.finishRecording()

        #expect(repository.savedEntries.isEmpty)
        #expect(sut.recordingTooShort)
    }

    @Test(.timeLimit(.minutes(1)))
    func aRecorderThatCannotStartSaysSoInTheSheet() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip(recorder: MockVoiceRecorder(startError: MockRepositoryError()))
        defer { observing.cancel() }

        await sut.startRecording()

        #expect(sut.recordingFailed)
        #expect(!sut.saveFailed)
        #expect(sut.recordingStartedAt == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingDiscardsTheRecording() async {
        let recorder = MockVoiceRecorder()
        let repository = MockEntryRepository()
        let (sut, _, observing) = await makeSUTWithOngoingTrip(entries: repository, recorder: recorder)
        defer { observing.cancel() }

        await sut.startRecording()
        await sut.cancelRecording()

        #expect(recorder.wasCancelled)
        #expect(repository.savedEntries.isEmpty)
    }

    /// The recorder throws CancellationError when the sheet closed before recording began: not a failure to report.
    @Test(.timeLimit(.minutes(1)))
    func closingTheSheetBeforeRecordingStartsIsNotAnError() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip(recorder: MockVoiceRecorder(startError: CancellationError()))
        defer { observing.cancel() }

        await sut.startRecording()

        #expect(sut.recordingStartedAt == nil)
        #expect(!sut.saveFailed)
    }

    @Test(.timeLimit(.minutes(1)))
    func explainsWhenTheMicrophoneIsOff() async {
        let (sut, _, observing) = await makeSUTWithOngoingTrip(recorder: MockVoiceRecorder(startError: VoiceRecorderError.microphoneAccessDenied))
        defer { observing.cancel() }

        await sut.startRecording()

        #expect(sut.microphoneDenied)
        #expect(sut.recordingStartedAt == nil)
    }
}

@MainActor
@Suite("CaptureViewModel recent entries")
struct CaptureViewModelRecentEntriesTests {
    @Test(.timeLimit(.minutes(1)))
    func showsTheTripsEntriesAndTheirTagsAsTheyChange() async {
        let repository = MockEntryRepository()
        let (sut, trip, tripObservation) = await makeSUTWithOngoingTrip(entries: repository)
        defer { tripObservation.cancel() }
        var changes = Changes { sut.recentEntries }
        #expect(await changes.next() == [])

        let observing = Task { await sut.observeRecentEntries() }
        defer { observing.cancel() }

        let saved = Entry(tripID: trip.id, text: "Walked 20k steps.")
        repository.send([saved])
        #expect(await changes.next() == [saved])

        repository.send([saved.applying(EntryIndex(tags: ["walking"], mood: .tired))])
        #expect(await changes.next()?.first?.tags == ["walking", "tired"])
    }
}

@MainActor
private func makeSUT(
    availability: any AIModelAvailabilityService = MockAvailabilityService(),
    entries: any EntryRepository = MockEntryRepository(),
    trips: FakeTripRepository = FakeTripRepository(),
    indexingQueue: any IndexingQueue = MockIndexingQueue(),
    context: any EntryContextProvider = StubContextProvider(),
    media: any MediaStore = MockMediaStore(),
    recorder: any VoiceRecorder = MockVoiceRecorder()
) -> CaptureViewModel {
    CaptureViewModel(dependencies: AppDependencies(
        availability: availability,
        entries: entries,
        trips: trips,
        tripLifecycle: TripLifecycle(repository: trips),
        indexingQueue: indexingQueue,
        context: context,
        media: media,
        recorder: recorder
    ))
}

/// A view model already showing an ongoing trip. Cancel the returned task when done.
@MainActor
private func makeSUTWithOngoingTrip(
    entries: any EntryRepository = MockEntryRepository(),
    indexingQueue: any IndexingQueue = MockIndexingQueue(),
    media: any MediaStore = MockMediaStore(),
    recorder: any VoiceRecorder = MockVoiceRecorder()
) async -> (CaptureViewModel, Trip, Task<Void, Never>) {
    let trip = Trip(name: "Japan")
    let sut = makeSUT(
        entries: entries,
        trips: FakeTripRepository(trips: [trip]),
        indexingQueue: indexingQueue,
        media: media,
        recorder: recorder
    )
    var ongoing = Changes { sut.ongoingTrip }
    _ = await ongoing.next()
    let observing = Task { await sut.observeTrips() }
    _ = await ongoing.next()
    return (sut, trip, observing)
}

/// Waits for a view model property to change instead of sleeping.
/// `Observations` emits the current value first, then each new value.
private struct Changes<Value: Sendable> {
    private var iterator: Observations<Value, Never>.Iterator

    @MainActor
    init(_ observe: @escaping @MainActor @Sendable () -> Value) {
        iterator = Observations(observe).makeAsyncIterator()
    }

    /// Runs on the caller's actor (`#isolation`), so the iterator never leaves the test's actor.
    mutating func next(isolation: isolated (any Actor)? = #isolation) async -> Value? {
        await iterator.next(isolation: isolation)
    }
}
