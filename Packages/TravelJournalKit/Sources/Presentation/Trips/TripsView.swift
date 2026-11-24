import DesignSystem
import Domain
import Foundation
import SwiftUI

struct TripsView: View {
    @State private var viewModel: TripsViewModel
    private let dependencies: AppDependencies
    private let onStartTrip: () -> Void

    init(dependencies: AppDependencies, onStartTrip: @escaping () -> Void) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: TripsViewModel(dependencies: dependencies))
        self.onStartTrip = onStartTrip
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dsScreenBackground()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip, dependencies: dependencies)
                }
        }
        .task { await viewModel.observeTrips() }
        .task { await viewModel.observeEntries() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
        } else if viewModel.summaries.isEmpty {
            EmptyStateView(
                systemImage: "map",
                title: "No trips yet",
                message: "Start a trip, then capture notes, photos and voice notes as you go."
            ) {
                Button("Start a trip", action: onStartTrip)
                    .buttonStyle(.dsPrimary)
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Trips")
                        .font(.dsDisplay)
                        .foregroundStyle(Palette.ink)
                        .padding(.bottom, Spacing.xs)
                    SearchField(
                        text: $viewModel.query,
                        onSubmit: { Task { await viewModel.submitSearch() } },
                        onClear: viewModel.clearSearch
                    )
                    if viewModel.search == .idle {
                        ForEach(viewModel.summaries) { summary in
                            NavigationLink(value: summary.trip) {
                                TripCard(summary: summary, sky: viewModel.skies[summary.id] ?? .unknown)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        SearchResultsView(state: viewModel.search, photoURL: viewModel.photoURL(for:))
                    }
                }
                .padding(Spacing.l)
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
