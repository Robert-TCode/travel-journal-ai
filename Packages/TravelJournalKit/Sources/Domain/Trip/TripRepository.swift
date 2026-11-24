import Foundation

public protocol TripRepository: Sendable {
    /// Inserts the trip, or replaces the stored one with the same `id`.
    func save(_ trip: Trip) async throws

    /// All trips, newest first: the current list right away, then a new list after every change.
    func tripUpdates() async -> AsyncStream<[Trip]>

    func ongoingTrip() async throws -> Trip?

    func trip(withID id: UUID) async throws -> Trip?
}
