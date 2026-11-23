import Domain
import Foundation
import Observation
import UIKit

struct PendingPhoto: Identifiable {
    let id = UUID()
    let data: Data
    let thumbnail: UIImage?
}

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
    private(set) var pendingPhotos: [PendingPhoto] = []
    private(set) var recordingStartedAt: Date?
    private(set) var microphoneDenied = false
    private(set) var recordingFailed = false
    private(set) var recordingTooShort = false
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
        ongoingTrip != nil && !isSaving && (hasText || !pendingPhotos.isEmpty)
    }

    private var hasText: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The stored entry, or while it is being indexed, the same entry with the tags generated so far.
    func displayed(_ entry: Entry) -> Entry {
        dependencies.liveIndexing.preview(of: entry) ?? entry
    }

    func photoURL(for entry: Entry) -> URL? {
        entry.photoNames.first.map(dependencies.media.photoURL(named:))
    }

    func addPhoto(_ data: Data) async {
        let thumbnail = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 240, height: 240))
        pendingPhotos.append(PendingPhoto(data: data, thumbnail: thumbnail))
        didSave = false
    }

    func removePhoto(_ photo: PendingPhoto) {
        pendingPhotos.removeAll { $0.id == photo.id }
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

    func startRecording() async {
        microphoneDenied = false
        recordingFailed = false
        recordingTooShort = false
        do {
            try await dependencies.recorder.start()
            recordingStartedAt = .now
        } catch VoiceRecorderError.microphoneAccessDenied {
            microphoneDenied = true
        } catch is CancellationError {
            // The user closed the sheet before recording began; nothing went wrong.
        } catch {
            recordingFailed = true
        }
    }

    func cancelRecording() async {
        recordingStartedAt = nil
        await dependencies.recorder.cancel()
    }

    /// A voice note is its own entry: the audio is saved right away, the transcript follows with indexing.
    func finishRecording() async {
        recordingStartedAt = nil
        guard let tripID = ongoingTrip?.id else { return }
        guard let recording = await dependencies.recorder.stop() else {
            recordingTooShort = true
            return
        }
        saveFailed = false
        do {
            let audioName = try await dependencies.media.storeAudio(movingFrom: recording)
            let entry = Entry(tripID: tripID, text: "", audioName: audioName)
            try await dependencies.entries.save(entry)
            didSave = true
            await dependencies.indexingQueue.enqueue(entry)
        } catch {
            saveFailed = true
        }
    }

    /// The screen never waits for indexing, and may disappear while it runs.
    func save() async {
        guard canSave, let tripID = ongoingTrip?.id else { return }
        isSaving = true
        didSave = false
        saveFailed = false
        defer { isSaving = false }

        let entry: Entry
        var photoNames: [String] = []
        do {
            for photo in pendingPhotos {
                photoNames.append(try await dependencies.media.storePhoto(photo.data))
            }
            entry = Entry(tripID: tripID, text: noteText, photoNames: photoNames)
            try await dependencies.entries.save(entry)
        } catch {
            // The user keeps the photos in the composer and may retry; copies from this attempt would be orphans.
            for name in photoNames {
                await dependencies.media.deletePhoto(named: name)
            }
            saveFailed = true
            return
        }
        noteText = ""
        pendingPhotos = []
        didSave = true
        await dependencies.indexingQueue.enqueue(entry)
    }
}
