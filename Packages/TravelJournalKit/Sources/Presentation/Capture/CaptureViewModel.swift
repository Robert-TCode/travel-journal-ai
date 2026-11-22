import Domain
import Foundation
import Observation

@MainActor @Observable
final class CaptureViewModel {
    private let availabilityService: any AIModelAvailabilityService
    private let repository: any EntryRepository
    private let indexingQueue: any IndexingQueue
    private let tripID: UUID

    private(set) var availability: AIModelAvailability?

    var noteText = "" {
        didSet {
            // A new note starts: the confirmation belongs to the previous one.
            if !noteText.isEmpty { didSave = false }
        }
    }
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var saveFailed = false

    init(
        availabilityService: any AIModelAvailabilityService,
        repository: any EntryRepository,
        indexingQueue: any IndexingQueue,
        tripID: UUID
    ) {
        self.availabilityService = availabilityService
        self.repository = repository
        self.indexingQueue = indexingQueue
        self.tripID = tripID
    }

    var canSave: Bool {
        !isSaving && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Runs until the calling task is cancelled (SwiftUI cancels `.task` when the view disappears).
    func observeAvailability() async {
        for await availability in availabilityService.availabilityUpdates() {
            self.availability = availability
        }
    }

    /// Stores the note verbatim, then hands it to the app-level indexing queue.
    /// No model involved here: the screen never waits for indexing, and may disappear while it runs.
    func save() async {
        guard canSave else { return }
        isSaving = true
        didSave = false
        saveFailed = false
        defer { isSaving = false }

        let entry = Entry(tripID: tripID, text: noteText)
        do {
            try await repository.save(entry)
        } catch {
            saveFailed = true
            return
        }
        noteText = ""
        didSave = true
        await indexingQueue.enqueue(entry)
    }
}
