import Domain
import Foundation
import SwiftData

/// Highlights are stored as two parallel arrays: SwiftData stores arrays of strings natively, and the pair stays readable.
@Model
final class TripStoryRecord {
    @Attribute(.unique) var tripID: UUID
    var title: String
    var text: String
    var highlightEntryIDs: [String] = []
    var highlightCaptions: [String] = []
    var writer: String
    var fingerprint: String
    var createdAt: Date

    init(_ story: TripStory) {
        tripID = story.tripID
        title = ""
        text = ""
        writer = ""
        fingerprint = ""
        createdAt = story.createdAt
        update(from: story)
    }

    func update(from story: TripStory) {
        title = story.title
        text = story.text
        highlightEntryIDs = story.highlights.map(\.entryID.uuidString)
        highlightCaptions = story.highlights.map(\.caption)
        writer = story.writer.rawValue
        fingerprint = story.fingerprint
        createdAt = story.createdAt
    }

    var story: TripStory {
        TripStory(
            tripID: tripID,
            title: title,
            text: text,
            highlights: zip(highlightEntryIDs, highlightCaptions).compactMap { id, caption in
                UUID(uuidString: id).map { TripStory.Highlight(entryID: $0, caption: caption) }
            },
            writer: TripStory.Writer(rawValue: writer) ?? .onDevice,
            fingerprint: fingerprint,
            createdAt: createdAt
        )
    }
}

public actor SwiftDataTripStoryRepository: TripStoryRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    public func story(forTrip tripID: UUID) throws -> TripStory? {
        try record(forTrip: tripID)?.story
    }

    public func save(_ story: TripStory) throws {
        if let record = try record(forTrip: story.tripID) {
            record.update(from: story)
        } else {
            context.insert(TripStoryRecord(story))
        }
        try context.save()
    }

    private func record(forTrip tripID: UUID) throws -> TripStoryRecord? {
        var descriptor = FetchDescriptor<TripStoryRecord>(predicate: #Predicate { $0.tripID == tripID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
