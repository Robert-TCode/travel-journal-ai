import Domain
import Foundation

struct StubStoryWriter: TripStoryWriter {
    var result: Result<TripStory.Draft, any Error> = .success(TripStory.Draft(title: "", text: "", highlights: []))

    var writer: TripStory.Writer { .onDevice }

    func write(trip: Trip, entries: [Entry]) async throws -> TripStory.Draft {
        try result.get()
    }
}

actor InMemoryStoryRepository: TripStoryRepository {
    private var stories: [UUID: TripStory] = [:]

    init(_ stories: [TripStory] = []) {
        for story in stories { self.stories[story.tripID] = story }
    }

    func story(forTrip tripID: UUID) -> TripStory? { stories[tripID] }
    func save(_ story: TripStory) { stories[story.tripID] = story }
}

extension TripStoryService {
    static func stub(
        writer: StubStoryWriter = StubStoryWriter(),
        repository: InMemoryStoryRepository = InMemoryStoryRepository()
    ) -> TripStoryService {
        TripStoryService(writer: writer, repository: repository)
    }
}
