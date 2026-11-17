import Testing
@testable import DataLayer

@Suite struct DataLayerSmokeTests {
    @Test func moduleLinks() {
        #expect(Bool(true))
    }
}
