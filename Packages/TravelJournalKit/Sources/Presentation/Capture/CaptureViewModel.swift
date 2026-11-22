import Domain
import Foundation
import Observation

@MainActor @Observable
final class CaptureViewModel {
    private let dependencies: AppDependencies

    private(set) var availability: AIModelAvailability?
    private(set) var hasLoadedTrips = false
    private(set) var ongoingTrip: Trip?
    private(set) var recentEntries: [Entry] = []

    var tripNameDraft = ""
    private(set) var isStartingTrip = false
    private(set) var startTripFailed = false

    var noteText = "" {
        didSet {
            if !noteText.isEmpty { didSave = false }
        }
    }
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var saveFailed = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var canStartTrip: Bool {
        !isStartingTrip && !tripNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSave: Bool {
        ongoingTrip != nil && !isSaving && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 1 on the day the trip started.
    func dayNumber(of trip: Trip, today: Date = .now, calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: trip.startedAt), to: calendar.startOfDay(for: today)).day ?? 0
        return days + 1
    }

    /// Runs until the calling task is cancelled (SwiftUI cancels `.task` when the view disappears).
    func observeAvailability() async {
        for await availability in dependencies.availability.availabilityUpdates() {
            self.availability = availability
        }
    }

    func observeTrips() async {
        for await trips in await dependencies.trips.tripUpdates() {
            ongoingTrip = trips.first(where: \.isOngoing)
            hasLoadedTrips = true
        }
    }

    /// Restarted by the view whenever the ongoing trip changes.
    func observeRecentEntries() async {
        guard let tripID = ongoingTrip?.id else {
            recentEntries = []
            return
        }
        for await entries in await dependencies.entries.entryUpdates(tripID: tripID) {
            recentEntries = entries
        }
    }

    /// Suggests the current city as the trip name; never overwrites what the user typed.
    func suggestTripName() async {
        guard tripNameDraft.isEmpty, let placeName = await dependencies.context.currentContext().placeName else { return }
        if tripNameDraft.isEmpty {
            tripNameDraft = placeName.components(separatedBy: ",").first ?? placeName
        }
    }

    func startTrip() async {
        guard canStartTrip else { return }
        isStartingTrip = true
        startTripFailed = false
        defer { isStartingTrip = false }
        do {
            _ = try await dependencies.tripLifecycle.start(named: tripNameDraft)
            tripNameDraft = ""
        } catch {
            startTripFailed = true
        }
    }

    func endOngoingTrip() async {
        guard let ongoingTrip else { return }
        try? await dependencies.tripLifecycle.end(ongoingTrip)
    }

    /// The screen never waits for indexing, and may disappear while it runs.
    func save() async {
        guard canSave, let tripID = ongoingTrip?.id else { return }
        isSaving = true
        didSave = false
        saveFailed = false
        defer { isSaving = false }

        let entry = Entry(tripID: tripID, text: noteText)
        do {
            try await dependencies.entries.save(entry)
        } catch {
            saveFailed = true
            return
        }
        noteText = ""
        didSave = true
        await dependencies.indexingQueue.enqueue(entry)
    }
}
