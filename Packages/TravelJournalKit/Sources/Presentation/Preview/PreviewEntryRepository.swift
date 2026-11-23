import Domain
import Foundation

struct PreviewEntryRepository: EntryRepository {
    var trips: [Trip] = PreviewTripRepository.sampleTrips

    func save(_ entry: Entry) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        single(sampleEntries.filter { $0.tripID == tripID })
    }

    func allEntryUpdates() -> AsyncStream<[Entry]> {
        single(sampleEntries)
    }

    func pendingEntries() -> [Entry] { [] }

    private var sampleEntries: [Entry] {
        guard let first = trips.first else { return [] }
        let second = trips.dropFirst().first ?? first
        return [
            Entry(tripID: first.id, text: "Black ice cream at Owakudani.", placeName: "Hakone, Kanagawa", weather: .cloudy, isDaytime: true),
            Entry(tripID: first.id, text: "Walked 20k steps today, my feet hurt.", weather: .clear, isDaytime: false, tags: ["walking", "steps", "tired"], indexingStatus: .done),
            Entry(tripID: first.id, text: "Best ramen of my life.", weather: .clear, isDaytime: false, tags: ["ramen", "happy"], indexingStatus: .done),
            Entry(tripID: second.id, text: "Fjord view at sunrise.", weather: .clear, isDaytime: true, tags: ["fjord", "sunrise", "amazed"], indexingStatus: .done),
        ]
    }

    private func single(_ entries: [Entry]) -> AsyncStream<[Entry]> {
        AsyncStream { continuation in
            continuation.yield(entries)
            continuation.finish()
        }
    }
}
