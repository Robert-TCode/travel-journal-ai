import SwiftUI
import Domain
import DataLayer
import Presentation

// Composition root: the only place that wires DataLayer implementations into Domain protocols.
@main
struct TravelJournalApp: App {
    private let availabilityService = SystemModelAvailabilityService()
    private let repository: InMemoryEntryRepository
    private let indexingCoordinator: IndexingCoordinator
    // Placeholder until start / end trip exists: every entry goes to this trip for now.
    private let currentTripID = UUID()

    init() {
        let repository = InMemoryEntryRepository()
        self.repository = repository
        self.indexingCoordinator = IndexingCoordinator(
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
        }
    }
}
