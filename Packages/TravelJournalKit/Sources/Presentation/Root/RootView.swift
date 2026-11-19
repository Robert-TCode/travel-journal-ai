import SwiftUI
import Domain

public struct RootView: View {
    private let availabilityService: any AIModelAvailabilityService
    private let repository: any EntryRepository
    private let currentTripID: UUID

    public init(
        availabilityService: any AIModelAvailabilityService,
        repository: any EntryRepository,
        currentTripID: UUID
    ) {
        self.availabilityService = availabilityService
        self.repository = repository
        self.currentTripID = currentTripID
    }

    public var body: some View {
        TabView {
            Tab("Trips", systemImage: "map") {
                TripsView()
            }
            Tab("Capture", systemImage: "plus.circle") {
                CaptureView(availabilityService: availabilityService, repository: repository, tripID: currentTripID)
            }
        }
    }
}

#Preview {
    RootView(availabilityService: PreviewAvailabilityService(.available), repository: PreviewEntryRepository(), currentTripID: UUID())
}
