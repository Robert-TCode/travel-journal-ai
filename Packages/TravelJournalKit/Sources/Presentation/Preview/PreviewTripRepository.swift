import Domain
import Foundation

struct PreviewTripRepository: TripRepository {
    static let sampleTrips = [
        Trip(name: "Japan", startedAt: .now.addingTimeInterval(-2 * 86_400)),
        Trip(name: "Norway", startedAt: Date(timeIntervalSince1970: 1_754_000_000), endedAt: Date(timeIntervalSince1970: 1_754_800_000)),
        Trip(name: "Tuscany", startedAt: Date(timeIntervalSince1970: 1_746_000_000), endedAt: Date(timeIntervalSince1970: 1_746_700_000)),
    ]

    let trips: [Trip]

    func save(_ trip: Trip) async throws {}

    func tripUpdates() -> AsyncStream<[Trip]> {
        AsyncStream { continuation in
            continuation.yield(trips)
            continuation.finish()
        }
    }

    func ongoingTrip() -> Trip? {
        trips.first(where: \.isOngoing)
    }

    func trip(withID id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }
}
