import Domain
import FoundationModels
import Observation

public final class SystemModelAvailabilityService: AIModelAvailabilityService {
    private let model: SystemLanguageModel

    public init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    public func availabilityUpdates() -> AsyncStream<AIModelAvailability> {
        let model = self.model
        return AsyncStream { continuation in
            let task = Task {
                let updates = Observations { model.availability }
                for await update in updates {
                    continuation.yield(update.domainValue)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

extension SystemLanguageModel.Availability {
    var domainValue: AIModelAvailability {
        switch self {
        case .available: return .available
        case let .unavailable(reason):
            switch reason {
            case .deviceNotEligible: return .unavailable(reason: .notSupported)
            case .appleIntelligenceNotEnabled: return .unavailable(reason: .notEnabled)
            case .modelNotReady: return .unavailable(reason: .notReadyYet)
            @unknown default: return .unavailable(reason: .unknown)
            }
        }
    }
}
