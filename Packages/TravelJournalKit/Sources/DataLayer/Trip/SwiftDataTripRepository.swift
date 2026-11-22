import Domain
import Foundation
import SwiftData

public actor SwiftDataTripRepository: TripRepository {
    private let context: ModelContext
    private var observers: [UUID: AsyncStream<[Trip]>.Continuation] = [:]

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    public func save(_ trip: Trip) throws {
        let id = trip.id
        var descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first {
            record.update(from: trip)
        } else {
            context.insert(TripRecord(trip))
        }
        try context.save()

        let snapshot = (try? allTrips()) ?? []
        for continuation in observers.values {
            continuation.yield(snapshot)
        }
    }

    public func tripUpdates() -> AsyncStream<[Trip]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [Trip].self, bufferingPolicy: .bufferingNewest(1))
        let observerID = UUID()
        observers[observerID] = continuation
        continuation.yield((try? allTrips()) ?? [])
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(observerID) }
        }
        return stream
    }

    public func ongoingTrip() throws -> Trip? {
        var descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.endedAt == nil })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.trip
    }

    private func allTrips() throws -> [Trip] {
        try context.fetch(FetchDescriptor<TripRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])).map(\.trip)
    }

    private func removeObserver(_ id: UUID) {
        observers[id] = nil
    }
}
