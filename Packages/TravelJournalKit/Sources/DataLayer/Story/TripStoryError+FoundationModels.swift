import Domain
import Foundation
import FoundationModels

extension TripStoryError {
    /// Unlike indexing, an untyped runtime failure is not assumed to be temporary: the user retries by hand,
    /// and "try again in a moment" would be a promise the app can't keep.
    init(_ error: any Error) {
        switch error {
        case let error as TripStoryError:
            self = error
        case let error as LanguageModelError:
            switch error {
            case .contextSizeExceeded: self = .tooLong
            case .unsupportedLanguageOrLocale: self = .unsupportedLanguage
            case .guardrailViolation, .refusal: self = .declined
            case .rateLimited, .timeout: self = .notReady
            case .unsupportedCapability, .unsupportedTranscriptContent, .unsupportedGenerationGuide: self = .unexpected
            @unknown default: self = .unexpected
            }
        case SystemLanguageModel.Error.assetsUnavailable, LanguageModelSession.Error.concurrentRequests:
            self = .notReady
        default:
            self = .unexpected
        }
    }
}
