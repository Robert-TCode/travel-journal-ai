import SwiftUI
import Domain
import DataLayer
import Presentation

// Composition root: the only place that wires DataLayer implementations into Domain protocols.
@main
struct TravelJournalApp: App {
    private let availabilityService = SystemModelAvailabilityService()
    private let repository: SwiftDataEntryRepository
    private let indexingCoordinator: IndexingCoordinator
    private let currentTripID = Self.placeholderTripID()

    init() {
        do {
            repository = try SwiftDataEntryRepository.onDisk()
        } catch {
            fatalError("Couldn't open the journal store: \(error)")
        }
        indexingCoordinator = IndexingCoordinator(
            contextProvider: DeviceEntryContextProvider(),
            indexer: FoundationModelsEntryIndexer(),
            repository: repository
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                availabilityService: availabilityService,
                repository: repository,
                indexingQueue: indexingCoordinator,
                currentTripID: currentTripID
            )
            .task { await indexingCoordinator.resumePendingEntries() }
        }
    }

    /// Until start / end trip exists, every entry goes to one trip that survives relaunches.
    private static func placeholderTripID() -> UUID {
        let key = "placeholderTripID"
        if let stored = UserDefaults.standard.string(forKey: key).flatMap(UUID.init(uuidString:)) {
            return stored
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }
}
