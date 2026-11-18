import SwiftUI
import Domain

public struct RootView: View {
    private let availabilityService: any AIModelAvailabilityService

    public init(availabilityService: any AIModelAvailabilityService) {
        self.availabilityService = availabilityService
    }

    public var body: some View {
        TabView {
            Tab("Trips", systemImage: "map") {
                TripsView()
            }
            Tab("Capture", systemImage: "plus.circle") {
                CaptureView(availabilityService: availabilityService)
            }
        }
    }
}

#if DEBUG
#Preview {
    RootView(availabilityService: PreviewAvailabilityService(.available))
}
#endif
