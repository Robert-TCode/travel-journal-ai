#if DEBUG
import DataLayer
import Domain
import Foundation
import Observation

/// Writes the story of every trip on this phone with the real on-device writer and reports it to
/// Documents/StoryEval/report.md, without saving anything. On the device because the simulator's model fails on it.
/// The report quotes the journal's stories: it is personal and stays out of the repo.
@MainActor @Observable
final class StoryEvalRunner: EvalRunner {
    private(set) var progress = "Waiting"
    private(set) var isFinished = false

    static let folder = URL.documentsDirectory.appending(path: "StoryEval")

    private let entries: any EntryRepository
    private let trips: any TripRepository

    init(entries: any EntryRepository, trips: any TripRepository) {
        self.entries = entries
        self.trips = trips
    }

    func run() async {
        try? FileManager.default.removeItem(at: Self.folder.appending(path: "report.md"))
        let allTrips = await first(of: trips.tripUpdates())
        let allEntries = await first(of: entries.allEntryUpdates())
        let writer = FoundationModelsTripStoryWriter()
        let clock = ContinuousClock()
        var sections: [String] = []
        for (number, trip) in allTrips.enumerated() {
            let tripEntries = allEntries.filter { $0.tripID == trip.id }.sorted { $0.createdAt < $1.createdAt }
            guard !tripEntries.isEmpty else { continue }
            progress = "\(number + 1)/\(allTrips.count): \(trip.name)"
            let start = clock.now
            do {
                let draft = try await withTimeout(.seconds(120)) { try await writer.write(trip: trip, entries: tripEntries) }
                let milliseconds = Int(start.duration(to: clock.now) / .milliseconds(1))
                let titles = Dictionary(tripEntries.map { ($0.id, SpotlightEntryIndex.title(for: $0)) }, uniquingKeysWith: { first, _ in first })
                let highlights = draft.highlights.map { "- \(titles[$0.entryID] ?? "?"): \($0.caption)" }
                sections.append("""
                    ## \(trip.name): \(tripEntries.count) entries, \(milliseconds) ms, thermal \(ProcessInfo.processInfo.thermalState.label)

                    **\(draft.title)**

                    \(draft.text)

                    \(highlights.joined(separator: "\n"))
                    """)
            } catch {
                sections.append("## \(trip.name): \(tripEntries.count) entries\n\nERROR \(error)")
            }
        }
        let report = "# Story eval\n\n\(Date.now.formatted(date: .abbreviated, time: .shortened))\n\n" + sections.joined(separator: "\n\n")
        writeReport(report, in: Self.folder)
        progress = "Done."
        isFinished = true
    }

    private func first<Element>(of stream: AsyncStream<[Element]>) async -> [Element] {
        for await elements in stream {
            return elements
        }
        return []
    }
}
#endif
