import Domain
import Foundation
import FoundationModels
import Testing
@testable import DataLayer

/// The framework's error types have public initializers, so every branch is testable without running a model.
@Suite("Model errors to indexing errors")
struct IndexingErrorMappingTests {
    @Test func aNoteTooLongForTheContextFails() {
        let error = LanguageModelError.contextSizeExceeded(.init(contextSize: 8192, tokenCount: 9000, debugDescription: ""))

        #expect(IndexingError(error) == .failed(.tooLong))
    }

    @Test func anUnsupportedLanguageFails() {
        let error = LanguageModelError.unsupportedLanguageOrLocale(.init(languageCode: "de", debugDescription: ""))

        #expect(IndexingError(error) == .failed(.unsupportedLanguage))
    }

    @Test func guardrailsAndRefusalsAreDeclined() {
        #expect(IndexingError(LanguageModelError.guardrailViolation(.init(debugDescription: ""))) == .failed(.declined))
        #expect(IndexingError(LanguageModelError.refusal(.init(explanation: "", debugDescription: ""))) == .failed(.declined))
    }

    @Test func busyOrSlowIsTemporary() {
        #expect(IndexingError(LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: ""))) == .temporarilyUnavailable)
        #expect(IndexingError(LanguageModelError.timeout(.init(debugDescription: ""))) == .temporarilyUnavailable)
        #expect(IndexingError(LanguageModelSession.Error.concurrentRequests) == .temporarilyUnavailable)
    }

    @Test func aModelStillDownloadingIsTemporary() {
        let error = SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: ""))

        #expect(IndexingError(error) == .temporarilyUnavailable)
    }

    @Test func anUntypedModelRuntimeErrorIsTemporary() {
        let error = NSError(domain: "FoundationModels.LanguageModelError", code: -1)

        #expect(IndexingError(error) == .temporarilyUnavailable)
    }

    @Test func anythingElseIsUnexpected() {
        #expect(IndexingError(CocoaError(.fileNoSuchFile)) == .failed(.unexpected))
    }
}
