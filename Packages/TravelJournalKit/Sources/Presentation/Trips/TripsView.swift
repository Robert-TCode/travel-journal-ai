import SwiftUI

struct TripsView: View {
    @State private var viewModel: TripsViewModel
    private let onStartTrip: () -> Void

    init(dependencies: AppDependencies, onStartTrip: @escaping () -> Void) {
        _viewModel = State(initialValue: TripsViewModel(dependencies: dependencies))
        self.onStartTrip = onStartTrip
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trips")
                .navigationBarTitleDisplayMode(.inline)
        }
        .task { await viewModel.observeTrips() }
        .task { await viewModel.observeEntries() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
        } else if viewModel.summaries.isEmpty {
            ContentUnavailableView {
                Label("No trips yet", systemImage: "map")
            } description: {
                Text("Start a trip, then capture notes, photos and voice memos as you go.")
            } actions: {
                Button("Start a trip", action: onStartTrip)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.summaries) { summary in
                        TripCard(summary: summary)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview("Trips") {
    TripsView(dependencies: .preview(), onStartTrip: {})
}

#Preview("No trips") {
    TripsView(dependencies: .preview(trips: []), onStartTrip: {})
}
