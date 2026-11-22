import Domain
import Foundation
import Synchronization

/// Behaves like a real store: keeps trips newest first and notifies every observer on save.
/// `ongoingTrip()` yields a few times so concurrent callers can interleave, as with a real store.
final class FakeTripRepository: TripRepository {
    private let state: Mutex<(trips: [Trip], observers: [AsyncStream<[Trip]>.Continuation])>

    init(trips: [Trip] = []) {
        state = Mutex((trips, []))
    }

    var trips: [Trip] { state.withLock { $0.trips } }

    func save(_ trip: Trip) async throws {
        state.withLock { state in
            if let index = state.trips.firstIndex(where: { $0.id == trip.id }) {
                state.trips[index] = trip
            } else {
                state.trips.insert(trip, at: 0)
            }
            for observer in state.observers { observer.yield(state.trips) }
        }
    }

    func tripUpdates() -> AsyncStream<[Trip]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [Trip].self)
        state.withLock { state in
            state.observers.append(continuation)
            continuation.yield(state.trips)
        }
        return stream
    }

    func ongoingTrip() async -> Trip? {
        for _ in 0..<5 { await Task.yield() }
        return trips.first(where: \.isOngoing)
    }
}
