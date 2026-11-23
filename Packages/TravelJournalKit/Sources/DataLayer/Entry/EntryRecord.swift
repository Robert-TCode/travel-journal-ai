import Domain
import Foundation
import SwiftData

/// Enums are stored as raw values, so renaming a Swift case doesn't silently break stored data.
@Model
final class EntryRecord {
    @Attribute(.unique) var id: UUID
    var tripID: UUID
    var text: String
    var photoNames: [String] = []
    var audioName: String?
    var transcript: String?
    var createdAt: Date
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
    var weather: String?
    var dayPhase: String?
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
        photoNames = entry.photoNames
        audioName = entry.audioName
        transcript = entry.transcript
        latitude = entry.coordinate?.latitude
        longitude = entry.coordinate?.longitude
        placeName = entry.placeName
        weather = entry.weather?.rawValue
        dayPhase = entry.dayPhase?.rawValue
        tags = entry.tags
        indexingStatus = entry.indexingStatus.rawValue
    }

    var entry: Entry {
        Entry(
            id: id,
            tripID: tripID,
            text: text,
            photoNames: photoNames,
            audioName: audioName,
            transcript: transcript,
            createdAt: createdAt,
            coordinate: latitude.flatMap { latitude in
                longitude.map { Coordinate(latitude: latitude, longitude: $0) }
            },
            placeName: placeName,
            weather: weather.flatMap(WeatherCondition.init(rawValue:)),
            dayPhase: dayPhase.flatMap(DayPhase.init(rawValue:)),
            tags: tags,
            indexingStatus: Entry.IndexingStatus(rawValue: indexingStatus) ?? .pending
        )
    }
}
