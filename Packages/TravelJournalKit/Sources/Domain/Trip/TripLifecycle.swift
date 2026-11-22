import Foundation

public enum TripLifecycleError: Error, Equatable {
    case anotherTripIsOngoing
    case emptyName
}

/// The only place that starts or ends trips, so "at most one ongoing trip" holds everywhere.
public actor TripLifecycle {
    private let repository: any TripRepository
    // Actor methods can interleave at every `await`: without this, two quick taps on "Start trip"
    // could both see no ongoing trip before either one saves.
    private var isStarting = false

    public init(repository: any TripRepository) {
        self.repository = repository
    }

    public func start(named name: String, at date: Date = .now) async throws -> Trip {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TripLifecycleError.emptyName }
        guard !isStarting else { throw TripLifecycleError.anotherTripIsOngoing }
        isStarting = true
        defer { isStarting = false }

        guard try await repository.ongoingTrip() == nil else { throw TripLifecycleError.anotherTripIsOngoing }
        let trip = Trip(name: trimmed, startedAt: date)
        try await repository.save(trip)
        return trip
    }

    public func end(_ trip: Trip, at date: Date = .now) async throws {
        var ended = trip
        ended.endedAt = date
        try await repository.save(ended)
    }
}
