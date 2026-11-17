import SwiftUI

struct CaptureView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Nothing to capture yet",
                systemImage: "plus.circle",
                description: Text("Photos, voice notes and text will go here.")
            )
            .navigationTitle("Capture")
        }
    }
}

#Preview {
    CaptureView()
}
