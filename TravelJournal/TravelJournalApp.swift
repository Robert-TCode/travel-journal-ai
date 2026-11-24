import SwiftUI
import Domain
import DataLayer
import Presentation

// Composition root: the only place that wires DataLayer implementations into Domain protocols.
@main
struct TravelJournalApp: App {
    private let dependencies: AppDependencies
    private let indexingCoordinator: IndexingCoordinator
    private let searchableEntries: SearchIndexingEntryRepository

    init() {
        let store: JournalStore
        do {
            store = try JournalStore.onDisk()
        } catch {
            fatalError("Couldn't open the journal store: \(error)")
        }
        let context = DeviceEntryContextProvider()
        let media = FileMediaStore()
        let liveIndexing = LiveIndexing()
        let entries = SearchIndexingEntryRepository(
            base: store.entries,
            trips: store.trips,
            searchIndex: SpotlightEntryIndex(media: media)
        )
        searchableEntries = entries
        indexingCoordinator = IndexingCoordinator(
            contextProvider: context,
            transcriber: SpeechTranscriberService(media: media),
            indexer: FoundationModelsEntryIndexer(media: media),
            repository: entries,
            live: liveIndexing
        )
        dependencies = AppDependencies(
            availability: SystemModelAvailabilityService(),
            entries: entries,
            trips: store.trips,
            tripLifecycle: TripLifecycle(repository: store.trips),
            indexingQueue: indexingCoordinator,
            context: context,
            media: media,
            recorder: AudioFileVoiceRecorder(),
            liveIndexing: liveIndexing
        )
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-photoEval") {
                PhotoEvalView()
            } else {
                app
            }
            #else
            app
            #endif
        }
    }

    private var app: some View {
        RootView(dependencies: dependencies)
            .task { await indexingCoordinator.resumePendingEntries() }
            .task(priority: .background) { await searchableEntries.reindexAll() }
    }
}
