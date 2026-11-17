public enum AIModelAvailability: Sendable, Equatable {
    case available
    case unavailable(reason: UnavailabilityReason)

    public enum UnavailabilityReason: Sendable, Equatable {
        case notSupported
        case notEnabled
        case notReadyYet
        case unknown
    }
}
