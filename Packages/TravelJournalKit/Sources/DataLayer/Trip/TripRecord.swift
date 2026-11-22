import Domain
import Foundation
import SwiftData

@Model
final class TripRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?

    init(_ trip: Trip) {
        id = trip.id
        name = trip.name
        startedAt = trip.startedAt
        endedAt = trip.endedAt
    }

    func update(from trip: Trip) {
        name = trip.name
        endedAt = trip.endedAt
    }

    var trip: Trip {
        Trip(id: id, name: name, startedAt: startedAt, endedAt: endedAt)
    }
}
