import Domain

/// Emits a fixed availability, so previews can show every state without touching Settings.
struct PreviewAvailabilityService: AIModelAvailabilityService {
    private let availability: AIModelAvailability

    init(_ availability: AIModelAvailability) {
        self.availability = availability
    }

    func availabilityUpdates() -> AsyncStream<AIModelAvailability> {
        AsyncStream { continuation in
            continuation.yield(availability)
            continuation.finish()
        }
    }
}
