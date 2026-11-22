import Foundation

/// A memory as the user captured it. `text` is stored verbatim; the model only ever adds metadata next to it.
public struct Entry: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let tripID: UUID
    public var text: String
    public let createdAt: Date

    public var coordinate: Coordinate?
    public var placeName: String?
    public var weather: WeatherCondition?
    public var isDaytime: Bool?

    // The mood is stored here as one of the tags.
    public var tags: [String]
    public var indexingStatus: IndexingStatus

    public init(
        id: UUID = UUID(),
        tripID: UUID,
        text: String,
        createdAt: Date = .now,
        coordinate: Coordinate? = nil,
        placeName: String? = nil,
        weather: WeatherCondition? = nil,
        isDaytime: Bool? = nil,
        tags: [String] = [],
        indexingStatus: IndexingStatus = .pending
    ) {
        self.id = id
        self.tripID = tripID
        self.text = text
        self.createdAt = createdAt
        self.coordinate = coordinate
        self.placeName = placeName
        self.weather = weather
        self.isDaytime = isDaytime
        self.tags = tags
        self.indexingStatus = indexingStatus
    }

    /// Where the silent, after-save indexing stands. Persisted, so pending work survives an app restart.
    public enum IndexingStatus: Sendable, Equatable {
        case pending
        case done
        case failed
    }
}
