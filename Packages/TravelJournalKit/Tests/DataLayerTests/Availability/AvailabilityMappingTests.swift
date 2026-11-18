import FoundationModels
import Testing
import Domain
@testable import DataLayer

@Suite("SystemLanguageModel availability mapping")
struct AvailabilityMappingTests {
    @Test func availableMapsToAvailable() {
        #expect(SystemLanguageModel.Availability.available.domainValue == .available)
    }

    @Test(arguments: [
        (SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible, AIModelAvailability.UnavailabilityReason.notSupported),
        (.appleIntelligenceNotEnabled, .notEnabled),
        (.modelNotReady, .notReadyYet),
    ])
    func unavailableReasonsMapToDomainReasons(
        _ reason: SystemLanguageModel.Availability.UnavailableReason,
        _ expected: AIModelAvailability.UnavailabilityReason
    ) {
        #expect(SystemLanguageModel.Availability.unavailable(reason).domainValue == .unavailable(reason: expected))
    }
}
