import SwiftUI

struct TripsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No trips yet",
                systemImage: "map",
                description: Text("Start a trip from the Capture tab.")
            )
            .navigationTitle("Trips")
        }
    }
}

#Preview {
    TripsView()
}
