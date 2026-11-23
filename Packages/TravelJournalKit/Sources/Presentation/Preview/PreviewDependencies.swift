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
            liveIndexing: LiveIndexing()
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
