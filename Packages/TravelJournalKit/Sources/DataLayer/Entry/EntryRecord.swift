import Domain
import Foundation
import SwiftData

/// Enums are stored as raw values, so renaming a Swift case doesn't silently break stored data.
@Model
final class EntryRecord {
    @Attribute(.unique) var id: UUID
    var tripID: UUID
    var text: String
    var createdAt: Date
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
    var weather: String?
    var isDaytime: Bool?
    var tags: [String]
    var indexingStatus: String

    init(_ entry: Entry) {
        id = entry.id
        tripID = entry.tripID
        text = entry.text
        createdAt = entry.createdAt
        tags = []
        indexingStatus = ""
        update(from: entry)
    }

    func update(from entry: Entry) {
        text = entry.text
        latitude = entry.coordinate?.latitude
        longitude = entry.coordinate?.longitude
        placeName = entry.placeName
        weather = entry.weather?.rawValue
        isDaytime = entry.isDaytime
        tags = entry.tags
        indexingStatus = entry.indexingStatus.rawValue
    }

    var entry: Entry {
        Entry(
            id: id,
            tripID: tripID,
            text: text,
            createdAt: createdAt,
            coordinate: latitude.flatMap { latitude in
                longitude.map { Coordinate(latitude: latitude, longitude: $0) }
            },
            placeName: placeName,
            weather: weather.flatMap(WeatherCondition.init(rawValue:)),
            isDaytime: isDaytime,
            tags: tags,
            indexingStatus: Entry.IndexingStatus(rawValue: indexingStatus) ?? .pending
        )
    }
}
