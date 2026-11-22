import SwiftUI
import Domain

/// Chooses between starting a trip and capturing into the ongoing one, and owns the trip-level actions.
struct CaptureView: View {
    @State private var viewModel: CaptureViewModel
    @State private var isConfirmingEnd = false

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: CaptureViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Capture")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if viewModel.ongoingTrip != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("End trip") { isConfirmingEnd = true }
                        }
                    }
                }
                .confirmationDialog(
                    "End \(viewModel.ongoingTrip?.name ?? "this trip")?",
                    isPresented: $isConfirmingEnd,
                    titleVisibility: .visible
                ) {
                    Button("End trip", role: .destructive) {
                        Task { await viewModel.endOngoingTrip() }
                    }
                } message: {
                    Text("Its memories stay in Trips. New memories will need a new trip.")
                }
        }
        .task { await viewModel.observeAvailability() }
        .task { await viewModel.observeTrips() }
        .task(id: viewModel.ongoingTrip?.id) { await viewModel.observeRecentEntries() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoadedTrips {
            ProgressView()
        } else if let trip = viewModel.ongoingTrip {
            NoteComposerView(viewModel: viewModel, trip: trip)
        } else {
            StartTripView(viewModel: viewModel)
        }
    }
}

#Preview("Ongoing trip") {
    CaptureView(dependencies: .preview())
}

#Preview("No trip") {
    CaptureView(dependencies: .preview(trips: []))
}

#Preview("Smart tags off") {
    CaptureView(dependencies: .preview(availability: .unavailable(reason: .notEnabled)))
}
