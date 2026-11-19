import SwiftUI
import Domain

public struct RootView: View {
    private let availabilityService: any AIModelAvailabilityService
    private let repository: any EntryRepository

    public init(availabilityService: any AIModelAvailabilityService, repository: any EntryRepository) {
        self.availabilityService = availabilityService
        self.repository = repository
    }

    public var body: some View {
        TabView {
            Tab("Trips", systemImage: "map") {
                TripsView()
            }
            Tab("Capture", systemImage: "plus.circle") {
                CaptureView(availabilityService: availabilityService, repository: repository)
            }
        }
    }
}

#Preview {
    RootView(availabilityService: PreviewAvailabilityService(.available), repository: PreviewEntryRepository())
}
