import DesignSystem
import Domain
import Foundation
import Observation

@MainActor @Observable
final class TripDetailViewModel {
    let trip: Trip
    private let dependencies: AppDependencies

    /// Oldest first: a trip reads from its first day.
    private(set) var entries: [Entry] = []
    private(set) var story: TripStory?
    /// False when entries changed after the story was written: it is still shown, with an offer to update it.
    private(set) var storyIsCurrent = false
    private(set) var isWritingStory = false
    private(set) var storyFailure: TripStoryError?

    init(trip: Trip, dependencies: AppDependencies) {
        self.trip = trip
        self.dependencies = dependencies
    }

    var writer: TripStory.Writer { dependencies.stories.writerKind }

    var sky: Sky { Sky.dominant(in: entries) }

    /// Distinct places in trip order, city part only: "Kyoto · Osaka".
    var places: [String] {
        var seen = Set<String>()
        return entries
            .compactMap { $0.placeName?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) }
            .filter { seen.insert($0).inserted }
    }

    struct Day: Identifiable {
        let number: Int
        let date: Date
        let entries: [Entry]
        var id: Date { date }
    }

    func days(calendar: Calendar = .current) -> [Day] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted().enumerated().map { index, date in
            Day(number: index + 1, date: date, entries: grouped[date] ?? [])
        }
    }

    /// Highlights paired with their stored entries; one whose entry is gone is skipped.
    var highlights: [(highlight: TripStory.Highlight, entry: Entry)] {
        let byID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return (story?.highlights ?? []).compactMap { highlight in
            byID[highlight.entryID].map { (highlight, $0) }
        }
    }

    func photoURL(for entry: Entry) -> URL? {
        entry.photoNames.first.map(dependencies.media.photoURL(named:))
    }

    func observeEntries() async {
        for await entries in await dependencies.entries.entryUpdates(tripID: trip.id) {
            self.entries = entries.sorted { $0.createdAt < $1.createdAt }
            await loadStoredStory()
        }
    }

    /// Never writes on its own: only the user's tap spends a model call.
    func tellStory() async {
        guard !isWritingStory, !entries.isEmpty else { return }
        isWritingStory = true
        storyFailure = nil
        defer { isWritingStory = false }
        do {
            let written = try await dependencies.stories.writeStory(for: trip, entries: entries)
            story = written
            // Entries may have changed while the model wrote; compare with what is there now.
            storyIsCurrent = written.fingerprint == TripStory.fingerprint(of: entries)
        } catch {
            storyFailure = error as? TripStoryError ?? .unexpected
        }
    }

    private func loadStoredStory() async {
        guard !isWritingStory, let stored = await dependencies.stories.storedStory(for: trip, entries: entries) else { return }
        story = stored.story
        storyIsCurrent = stored.isCurrent
    }
}
