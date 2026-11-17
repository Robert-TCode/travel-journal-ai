import SwiftUI

public struct RootView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab("Trips", systemImage: "map") {
                TripsView()
            }
            Tab("Capture", systemImage: "plus.circle") {
                CaptureView()
            }
        }
    }
}

#Preview {
    RootView()
}
