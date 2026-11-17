public protocol AIModelAvailabilityService: Sendable {
    func availabilityUpdates() -> AsyncStream<AIModelAvailability>
}
