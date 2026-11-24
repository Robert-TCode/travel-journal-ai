import DesignSystem
import Domain
import Foundation
import Observation

@MainActor @Observable
final class TripsViewModel {
    private let dependencies: AppDependencies
    private var trips: [Trip] = []
    private var entries: [Entry] = []

    private(set) var hasLoaded = false
    private(set) var summaries: [TripSummary] = []
    /// Each card is painted with the sky its trip saw most.
    private(set) var skies: [Trip.ID: Sky] = [:]

    var query = ""
    private(set) var search = SearchState.idle
    private var searchedIDs: [UUID] = []
    /// Bumped by every submit and clear, so only the latest search may change what the screen shows.
    private var searchGeneration = 0

    enum SearchState: Equatable {
        case idle
        case searching
        /// Empty means the journal has nothing that answers the question.
        case results([SearchResult])
        case failed
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func observeTrips() async {
        for await trips in await dependencies.trips.tripUpdates() {
            self.trips = trips
            hasLoaded = true
            refresh()
        }
    }

    func observeEntries() async {
        for await entries in await dependencies.entries.allEntryUpdates() {
            self.entries = entries
            refresh()
        }
    }

    /// Runs on submit, not on every keystroke: each search is two model calls.
    func submitSearch() async {
        let question = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return clearSearch() }
        searchGeneration += 1
        let generation = searchGeneration
        search = .searching
        do {
            let ids = try await dependencies.searcher.search(question)
            // A newer submit or a clear happened while the model worked: its answer wins.
            guard generation == searchGeneration else { return }
            searchedIDs = ids
            search = .results(SearchResult.results(for: ids, entries: entries, trips: trips))
        } catch {
            guard generation == searchGeneration else { return }
            search = .failed
        }
    }

    func clearSearch() {
        searchGeneration += 1
        query = ""
        searchedIDs = []
        search = .idle
    }

    func photoURL(for entry: Entry) -> URL? {
        entry.photoNames.first.map(dependencies.media.photoURL(named:))
    }

    private func refresh() {
        summaries = TripSummary.summaries(of: trips, entries: entries)
        skies = Dictionary(grouping: entries, by: \.tripID).mapValues { Sky.dominant(in: $0) }
        // Shown results follow edits to their entries, e.g. tags that finish indexing.
        if case .results = search {
            search = .results(SearchResult.results(for: searchedIDs, entries: entries, trips: trips))
        }
    }
}
