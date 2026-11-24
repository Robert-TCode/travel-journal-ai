import Foundation

/// Opens a trip's story instantly when one exists, and writes a new one only when asked:
/// writing costs a model call (and, with a cloud model, the user's daily quota), so it never happens on its own.
public struct TripStoryService: Sendable {
    private let writer: any TripStoryWriter
    private let repository: any TripStoryRepository
    private let now: @Sendable () -> Date

    public init(writer: any TripStoryWriter, repository: any TripStoryRepository, now: @escaping @Sendable () -> Date = { .now }) {
        self.writer = writer
        self.repository = repository
        self.now = now
    }

    public var writerKind: TripStory.Writer { writer.writer }

    /// The stored story, and whether it still matches the entries. An outdated story is still shown, marked as such.
    public func storedStory(for trip: Trip, entries: [Entry]) async -> (story: TripStory, isCurrent: Bool)? {
        guard let story = try? await repository.story(forTrip: trip.id) else { return nil }
        return (story, story.fingerprint == TripStory.fingerprint(of: entries))
    }

    public func writeStory(for trip: Trip, entries: [Entry]) async throws -> TripStory {
        let ordered = entries.sorted { $0.createdAt < $1.createdAt }
        guard !ordered.isEmpty else { throw TripStoryError.noEntries }
        let draft = try await writer.write(trip: trip, entries: ordered)
        let known = Set(ordered.map(\.id))
        var seen = Set<UUID>()
        let story = TripStory(
            tripID: trip.id,
            title: draft.title,
            text: draft.text,
            // A highlight must open a real entry; anything else is dropped rather than shown broken.
            highlights: draft.highlights.filter { known.contains($0.entryID) && seen.insert($0.entryID).inserted },
            writer: writer.writer,
            fingerprint: TripStory.fingerprint(of: entries),
            createdAt: now()
        )
        try? await repository.save(story)
        return story
    }
}

extension TripStory {
    /// Changes when anything the story could have used changes: an entry added, edited or re-tagged.
    /// FNV-1a over a canonical text, because Swift's `Hasher` is seeded per launch and can't be stored.
    public static func fingerprint(of entries: [Entry]) -> String {
        let canonical = entries
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { entry in
                [entry.id.uuidString, entry.text, entry.transcript ?? "", entry.tags.joined(separator: ","),
                 entry.landmark ?? "", entry.placeName ?? "", entry.photoNames.joined(separator: ",")]
                    .joined(separator: "\u{1F}")
            }
            .joined(separator: "\u{1E}")
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in canonical.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return String(hash, radix: 16)
    }
}
