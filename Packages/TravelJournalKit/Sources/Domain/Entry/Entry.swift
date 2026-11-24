import Foundation

/// A memory as the user captured it. `text` is stored verbatim; the model only ever adds metadata next to it.
public struct Entry: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let tripID: UUID
    public var text: String
    /// File names in the `MediaStore`, in the order the user added them.
    public var photoNames: [String]
    /// A voice note's audio file in the `MediaStore`; the recording itself is the memory.
    public var audioName: String?
    /// Written on device after saving, for indexing and search. Nil until transcription finishes.
    public var transcript: String?
    public let createdAt: Date

    public var coordinate: Coordinate?
    public var placeName: String?
    public var weather: WeatherCondition?
    public var dayPhase: DayPhase?
    /// Points of interest around the capture point, nearest first. Saved with the entry so indexing
    /// can run later (even after a relaunch) with the places that were there at that moment.
    public var nearbyPlaces: [String]
    /// One of `nearbyPlaces`, chosen by indexing when the memory is clearly about it.
    public var landmark: String?

    // The mood is stored here as one of the tags.
    public var tags: [String]
    /// Set by indexing, for search only.
    public var categories: [EntryCategory]
    public var indexingStatus: IndexingStatus
    /// Set only when `indexingStatus` is `.failed`.
    public var indexingFailure: IndexingFailure?

    public init(
        id: UUID = UUID(),
        tripID: UUID,
        text: String,
        photoNames: [String] = [],
        audioName: String? = nil,
        transcript: String? = nil,
        createdAt: Date = .now,
        coordinate: Coordinate? = nil,
        placeName: String? = nil,
        weather: WeatherCondition? = nil,
        dayPhase: DayPhase? = nil,
        nearbyPlaces: [String] = [],
        landmark: String? = nil,
        tags: [String] = [],
        categories: [EntryCategory] = [],
        indexingStatus: IndexingStatus = .pending,
        indexingFailure: IndexingFailure? = nil
    ) {
        self.id = id
        self.tripID = tripID
        self.text = text
        self.photoNames = photoNames
        self.audioName = audioName
        self.transcript = transcript
        self.createdAt = createdAt
        self.coordinate = coordinate
        self.placeName = placeName
        self.weather = weather
        self.dayPhase = dayPhase
        self.nearbyPlaces = nearbyPlaces
        self.landmark = landmark
        self.tags = tags
        self.categories = categories
        self.indexingStatus = indexingStatus
        self.indexingFailure = indexingFailure
    }

    /// Where the silent, after-save indexing stands. Persisted, so pending work survives an app restart.
    public enum IndexingStatus: String, Sendable, Equatable {
        case pending
        case done
        case failed
    }
}
