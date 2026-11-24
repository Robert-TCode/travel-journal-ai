import Domain
import Foundation

extension AppDependencies {
    @MainActor
    static func preview(
        availability: AIModelAvailability = .available,
        trips: [Trip] = PreviewTripRepository.sampleTrips
    ) -> AppDependencies {
        let tripRepository = PreviewTripRepository(trips: trips)
        return AppDependencies(
            availability: PreviewAvailabilityService(availability),
            entries: PreviewEntryRepository(trips: trips),
            trips: tripRepository,
            tripLifecycle: TripLifecycle(repository: tripRepository),
            indexingQueue: PreviewIndexingQueue(),
            context: PreviewContextProvider(),
            media: PreviewMediaStore(),
            recorder: PreviewVoiceRecorder(),
            liveIndexing: LiveIndexing(),
            searcher: PreviewMemorySearcher(),
            stories: TripStoryService(writer: PreviewStoryWriter(), repository: PreviewStoryRepository())
        )
    }
}

struct PreviewContextProvider: EntryContextProvider {
    func currentContext() async -> EntryContext {
        EntryContext(placeName: "Hakone, Kanagawa")
    }
}

struct PreviewMediaStore: MediaStore {
    func storePhoto(_ data: Data) async throws -> String { "preview.jpg" }

    func photoURL(named name: String) -> URL {
        URL.temporaryDirectory.appending(path: name)
    }

    func deletePhoto(named name: String) async {}

    func storeAudio(movingFrom url: URL) async throws -> String { "preview.m4a" }

    func audioURL(named name: String) -> URL {
        URL.temporaryDirectory.appending(path: name)
    }
}

struct PreviewVoiceRecorder: VoiceRecorder {
    func start() async throws {}
    func stop() async -> URL? { nil }
    func cancel() async {}
}

struct PreviewMemorySearcher: MemorySearcher {
    func search(_ question: String) async throws -> [UUID] { [] }
}

struct PreviewStoryWriter: TripStoryWriter {
    var writer: TripStory.Writer { .onDevice }

    func write(trip: Trip, entries: [Entry]) async throws -> TripStory.Draft {
        try await Task.sleep(for: .seconds(1))
        return TripStory.Draft(
            title: "Steam, ramen and sore feet",
            text: "You started at Owakudani, where the ice cream was black and the air smelled of sulphur. "
                + "By night you had walked twenty thousand steps, and the best ramen of your life made up for every one.",
            highlights: entries.prefix(2).map { TripStory.Highlight(entryID: $0.id, caption: "Where the trip began.") }
        )
    }
}

actor PreviewStoryRepository: TripStoryRepository {
    private var stories: [UUID: TripStory] = [:]

    func story(forTrip tripID: UUID) -> TripStory? { stories[tripID] }
    func save(_ story: TripStory) { stories[story.tripID] = story }
}
