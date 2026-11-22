import SwiftUI
import Domain
import DataLayer
import Presentation

// Composition root: the only place that wires DataLayer implementations into Domain protocols.
@main
struct TravelJournalApp: App {
    private let dependencies: AppDependencies
    private let indexingCoordinator: IndexingCoordinator

    init() {
        let store: JournalStore
        do {
            store = try JournalStore.onDisk()
        } catch {
            fatalError("Couldn't open the journal store: \(error)")
        }
        let context = DeviceEntryContextProvider()
        indexingCoordinator = IndexingCoordinator(
            contextProvider: context,
            indexer: FoundationModelsEntryIndexer(),
            repository: store.entries
        )
        dependencies = AppDependencies(
            availability: SystemModelAvailabilityService(),
            entries: store.entries,
            trips: store.trips,
            tripLifecycle: TripLifecycle(repository: store.trips),
            indexingQueue: indexingCoordinator,
            context: context
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .task { await indexingCoordinator.resumePendingEntries() }
        }
    }
}
