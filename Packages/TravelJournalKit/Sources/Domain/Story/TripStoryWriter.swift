import Foundation

/// Writes a trip's story. Implementations differ by model (on device now, Private Cloud Compute later);
/// the screen and the cache don't change when the model does.
public protocol TripStoryWriter: Sendable {
    var writer: TripStory.Writer { get }

    /// `entries` are the trip's entries, oldest first. Highlights must only point at these entries.
    func write(trip: Trip, entries: [Entry]) async throws -> TripStory.Draft
}

public protocol TripStoryRepository: Sendable {
    func story(forTrip tripID: UUID) async throws -> TripStory?
    /// Replaces the trip's previous story.
    func save(_ story: TripStory) async throws
}

/// Why a story wasn't written, in terms the screen can explain. Separate from `IndexingError`:
/// indexing retries silently on the next launch, while a story is retried by the user, who needs to know why.
public enum TripStoryError: Error, Equatable {
    /// Nothing to tell yet.
    case noEntries
    /// The journal doesn't fit the model's context, even with short notes.
    case tooLong
    /// Busy, rate limited or still downloading: trying again later can work.
    case notReady
    case unsupportedLanguage
    /// Guardrails or a refusal.
    case declined
    case unexpected
}
