import Domain
import Observation

@MainActor @Observable
final class CaptureViewModel {
    private let availabilityService: any AIModelAvailabilityService
    private let repository: any EntryRepository

    private(set) var availability: AIModelAvailability?

    var noteText = ""
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var saveFailed = false

    init(availabilityService: any AIModelAvailabilityService, repository: any EntryRepository) {
        self.availabilityService = availabilityService
        self.repository = repository
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

    /// Stores the note verbatim. No model involved: indexing happens later, outside this screen.
    func save() async {
        guard canSave else { return }
        isSaving = true
        didSave = false
        saveFailed = false
        defer { isSaving = false }

        do {
            try await repository.save(Entry(text: noteText))
            noteText = ""
            didSave = true
        } catch {
            saveFailed = true
        }
    }
}
