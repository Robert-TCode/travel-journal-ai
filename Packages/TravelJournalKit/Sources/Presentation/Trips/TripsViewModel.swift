import Domain
import Observation

@MainActor @Observable
final class TripsViewModel {
    private let dependencies: AppDependencies
    private var trips: [Trip] = []
    private var entries: [Entry] = []

    private(set) var hasLoaded = false
    private(set) var summaries: [TripSummary] = []

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

    private func refresh() {
        summaries = TripSummary.summaries(of: trips, entries: entries)
    }
}
