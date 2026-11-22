import Domain
import Foundation

extension AppDependencies {
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
            media: PreviewMediaStore()
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
}
