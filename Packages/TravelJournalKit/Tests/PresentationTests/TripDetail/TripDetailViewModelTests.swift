import Domain
import Foundation
import Testing
@testable import Presentation

private struct ModelBusy: Error {}

@MainActor
@Suite("TripDetailViewModel")
struct TripDetailViewModelTests {
    private let trip = Trip(name: "Japan")
    private let entries = MockEntryRepository()

    private func makeSUT(stories: TripStoryService = .stub()) -> TripDetailViewModel {
        let trips = FakeTripRepository(trips: [trip])
        return TripDetailViewModel(trip: trip, dependencies: AppDependencies(
            availability: MockAvailabilityService(),
            entries: entries,
            trips: trips,
            tripLifecycle: TripLifecycle(repository: trips),
            indexingQueue: MockIndexingQueue(),
            context: StubContextProvider(),
            media: MockMediaStore(),
            recorder: MockVoiceRecorder(),
            liveIndexing: LiveIndexing(),
            searcher: StubMemorySearcher(),
            stories: stories
        ))
    }

    private func observing(_ sut: TripDetailViewModel, _ stored: [Entry]) async -> Task<Void, Never> {
        let task = Task { await sut.observeEntries() }
        entries.send(stored)
        while sut.entries.count != stored.count { await Task.yield() }
        return task
    }

    @Test(.timeLimit(.minutes(1)))
    func groupsEntriesByDayOldestFirst() async {
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = Entry(tripID: trip.id, text: "Arrival", createdAt: Date(timeIntervalSince1970: 1_795_000_000))
        let dayTwo = Entry(tripID: trip.id, text: "Temple", createdAt: Date(timeIntervalSince1970: 1_795_090_000))
        let sut = makeSUT()
        let task = await observing(sut, [dayTwo, dayOne])
        defer { task.cancel() }

        let days = sut.days(calendar: calendar)

        #expect(days.map(\.number) == [1, 2])
        #expect(days.map { $0.entries.map(\.text) } == [["Arrival"], ["Temple"]])
    }

    @Test(.timeLimit(.minutes(1)))
    func tellingTheStoryShowsItWithItsHighlights() async {
        let ramen = Entry(tripID: trip.id, text: "Ramen", placeName: "Kyoto, Japan")
        let writer = StubStoryWriter(result: .success(TripStory.Draft(
            title: "Noodles", text: "You ate ramen.", highlights: [.init(entryID: ramen.id, caption: "Dinner")]
        )))
        let sut = makeSUT(stories: .stub(writer: writer))
        let task = await observing(sut, [ramen])
        defer { task.cancel() }

        await sut.tellStory()

        #expect(sut.story?.title == "Noodles")
        #expect(sut.storyIsCurrent)
        #expect(sut.highlights.map(\.entry) == [ramen])
        #expect(sut.places == ["Kyoto"])
    }

    /// An existing story opens with the trip, no model call; a newer entry marks it outdated.
    @Test(.timeLimit(.minutes(1)))
    func aStoredStoryOpensAndIsMarkedOutdatedByNewEntries() async {
        let ramen = Entry(tripID: trip.id, text: "Ramen")
        let stored = TripStory(
            tripID: trip.id, title: "Earlier", text: "Text", highlights: [], writer: .onDevice,
            fingerprint: TripStory.fingerprint(of: [ramen]), createdAt: .now
        )
        let sut = makeSUT(stories: .stub(repository: InMemoryStoryRepository([stored])))
        let task = await observing(sut, [ramen])
        defer { task.cancel() }
        while sut.story == nil { await Task.yield() }
        #expect(sut.storyIsCurrent)

        entries.send([ramen, Entry(tripID: trip.id, text: "Temple")])
        while sut.storyIsCurrent { await Task.yield() }

        #expect(sut.story?.title == "Earlier")
    }

    @Test(arguments: [
        (TripStoryError.tooLong as any Error, TripStoryError.tooLong),
        (TripStoryError.notReady, .notReady),
        (TripStoryError.declined, .declined),
        (ModelBusy(), .unexpected),
    ] as [(any Error, TripStoryError)])
    func aFailedStorySaysWhy(error: any Error, failure: TripStoryError) async {
        let sut = makeSUT(stories: .stub(writer: StubStoryWriter(result: .failure(error))))
        let task = await observing(sut, [Entry(tripID: trip.id, text: "Ramen")])
        defer { task.cancel() }

        await sut.tellStory()

        #expect(sut.storyFailure == failure)
        #expect(sut.story == nil)
        #expect(!sut.isWritingStory)
    }
}
