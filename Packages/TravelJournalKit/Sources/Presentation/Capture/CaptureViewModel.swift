import Domain
import Observation

@MainActor @Observable
final class CaptureViewModel {
    private let availabilityService: any AIModelAvailabilityService

    private(set) var availability: AIModelAvailability?

    init(availabilityService: any AIModelAvailabilityService) {
        self.availabilityService = availabilityService
    }

    /// Runs until the calling task is cancelled (SwiftUI cancels `.task` when the view disappears).
    func observeAvailability() async {
        for await availability in availabilityService.availabilityUpdates() {
            self.availability = availability
        }
    }
}
