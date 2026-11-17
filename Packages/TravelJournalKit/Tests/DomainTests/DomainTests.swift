import Testing
@testable import Domain

@Suite struct DomainSmokeTests {
    @Test func moduleLinks() {
        #expect(Bool(true))
    }
}
