import SwiftUI
import Domain
import DataLayer
import Presentation

// Composition root: the only place that wires DataLayer implementations into Domain protocols.
@main
struct TravelJournalApp: App {
    private let availabilityService = SystemModelAvailabilityService()
    private let repository = InMemoryEntryRepository()

    var body: some Scene {
        WindowGroup {
            RootView(availabilityService: availabilityService, repository: repository)
        }
    }
}
