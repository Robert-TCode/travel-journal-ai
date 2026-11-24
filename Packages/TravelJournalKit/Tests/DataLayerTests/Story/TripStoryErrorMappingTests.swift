import Domain
import Foundation
import FoundationModels
import Testing
@testable import DataLayer

/// Stories are retried by the user, so only failures that can really pass are reported as "not ready".
@Suite("Model errors to story errors")
struct TripStoryErrorMappingTests {
    @Test func aJournalTooLongForTheContextIsTooLong() {
        let error = LanguageModelError.contextSizeExceeded(.init(contextSize: 8192, tokenCount: 9000, debugDescription: ""))

        #expect(TripStoryError(error) == .tooLong)
    }

    @Test func busyOrDownloadingIsNotReady() {
        #expect(TripStoryError(LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: ""))) == .notReady)
        #expect(TripStoryError(SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: ""))) == .notReady)
        #expect(TripStoryError(LanguageModelSession.Error.concurrentRequests) == .notReady)
    }

    @Test func guardrailsAreDeclined() {
        #expect(TripStoryError(LanguageModelError.guardrailViolation(.init(debugDescription: ""))) == .declined)
    }

    /// Unlike indexing, which retries untyped runtime errors silently on the next launch.
    @Test func anUntypedRuntimeErrorIsUnexpected() {
        #expect(TripStoryError(NSError(domain: "FoundationModels.LanguageModelError", code: -1)) == .unexpected)
    }

    @Test func aStoryErrorPassesThrough() {
        #expect(TripStoryError(TripStoryError.tooLong) == .tooLong)
    }
}
