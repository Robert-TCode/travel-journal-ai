import SwiftUI
import Domain

enum AppTab: Hashable {
    case trips
    case capture
}

public struct RootView: View {
    private let dependencies: AppDependencies
    @State private var selectedTab = AppTab.trips

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Trips", systemImage: "map", value: .trips) {
                TripsView(dependencies: dependencies, onStartTrip: { selectedTab = .capture })
            }
            Tab("Capture", systemImage: "plus.circle", value: .capture) {
                CaptureView(dependencies: dependencies)
            }
        }
    }
}

#Preview {
    RootView(dependencies: .preview())
}
