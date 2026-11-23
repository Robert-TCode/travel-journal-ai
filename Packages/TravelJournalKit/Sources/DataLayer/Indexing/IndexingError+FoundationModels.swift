import Foundation
import Domain
import FoundationModels

extension IndexingError {
    /// iOS 27 split the old `GenerationError` into errors per owner: the language model, the system model's assets,
    /// the session, and parsing. Only the reason the user can act on (or wait for) survives the translation.
    init(_ error: any Error) {
        switch error {
        case let error as LanguageModelError:
            self = Self(error)
        case SystemLanguageModel.Error.assetsUnavailable:
            // The model is downloading, or Apple Intelligence was turned off meanwhile.
            self = .temporarilyUnavailable
        case LanguageModelSession.Error.concurrentRequests:
            self = .temporarilyUnavailable
        // Model-runtime failures that don't bridge to a typed case (missing image assets came as
        // FoundationModels.LanguageModelError code -1) aren't the note's fault: retry on the next launch.
        case let error as NSError where error.domain.hasPrefix("FoundationModels"):
            self = .temporarilyUnavailable
        default:
            self = .failed(.unexpected)
        }
    }

    private init(_ error: LanguageModelError) {
        switch error {
        case .contextSizeExceeded: self = .failed(.tooLong)
        case .unsupportedLanguageOrLocale: self = .failed(.unsupportedLanguage)
        case .guardrailViolation, .refusal: self = .failed(.declined)
        case .rateLimited, .timeout: self = .temporarilyUnavailable
        // Wrong guides, capabilities or transcript content are bugs in our request, not in the note.
        case .unsupportedCapability, .unsupportedTranscriptContent, .unsupportedGenerationGuide: self = .failed(.unexpected)
        @unknown default: self = .failed(.unexpected)
        }
    }
}
