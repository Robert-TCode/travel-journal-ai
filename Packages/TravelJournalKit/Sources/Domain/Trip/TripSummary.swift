/// What a trip card shows, derived from the trip and its entries.
public struct TripSummary: Sendable, Equatable, Identifiable {
    public let trip: Trip
    public let memoryCount: Int
    public let topTags: [String]

    public var id: Trip.ID { trip.id }

    public init(trip: Trip, memoryCount: Int, topTags: [String]) {
        self.trip = trip
        self.memoryCount = memoryCount
        self.topTags = topTags
    }

    /// Trips stay in the order given; top tags are the most frequent ones, ties broken alphabetically.
    public static func summaries(of trips: [Trip], entries: [Entry], topTagCount: Int = 3) -> [TripSummary] {
        let entriesByTrip = Dictionary(grouping: entries, by: \.tripID)
        return trips.map { trip in
            let tripEntries = entriesByTrip[trip.id] ?? []
            let counts = tripEntries.flatMap(\.tags).reduce(into: [:]) { $0[$1, default: 0] += 1 }
            let topTags = counts
                .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
                .prefix(topTagCount)
                .map(\.key)
            return TripSummary(trip: trip, memoryCount: tripEntries.count, topTags: topTags)
        }
    }
}
