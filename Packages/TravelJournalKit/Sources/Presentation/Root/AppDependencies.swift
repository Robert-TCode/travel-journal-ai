import Domain

/// Everything the screens need, built once in the composition root.
public struct AppDependencies: Sendable {
    let availability: any AIModelAvailabilityService
    let entries: any EntryRepository
    let trips: any TripRepository
    let tripLifecycle: TripLifecycle
    let indexingQueue: any IndexingQueue
    let context: any EntryContextProvider
    let media: any MediaStore
    let recorder: any VoiceRecorder
    let liveIndexing: LiveIndexing
    let searcher: any MemorySearcher
    let stories: TripStoryService

    public init(
        availability: any AIModelAvailabilityService,
        entries: any EntryRepository,
        trips: any TripRepository,
        tripLifecycle: TripLifecycle,
        indexingQueue: any IndexingQueue,
        context: any EntryContextProvider,
        media: any MediaStore,
        recorder: any VoiceRecorder,
        liveIndexing: LiveIndexing,
        searcher: any MemorySearcher,
        stories: TripStoryService
    ) {
        self.availability = availability
        self.entries = entries
        self.trips = trips
        self.tripLifecycle = tripLifecycle
        self.indexingQueue = indexingQueue
        self.context = context
        self.media = media
        self.recorder = recorder
        self.liveIndexing = liveIndexing
        self.searcher = searcher
        self.stories = stories
    }
}
