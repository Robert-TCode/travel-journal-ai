import DesignSystem
import Domain
import Foundation
import SwiftUI

struct TripDetailView: View {
    @State private var viewModel: TripDetailViewModel

    init(trip: Trip, dependencies: AppDependencies) {
        _viewModel = State(initialValue: TripDetailViewModel(trip: trip, dependencies: dependencies))
    }

    var body: some View {
        GeometryReader { proxy in
            content(topInset: proxy.safeAreaInsets.top)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.observeEntries() }
    }

    /// The sky runs up under the status bar and the back button, as on the capture screen;
    /// the title is pushed down by the same inset so the button never covers it.
    private func content(topInset: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SkyHeader(title: viewModel.trip.name, subtitle: subtitle, sky: viewModel.sky, topInset: topInset)
                VStack(alignment: .leading, spacing: Spacing.l) {
                    if viewModel.entries.isEmpty {
                        Text("No memories in this trip yet.")
                            .font(.dsBody)
                            .foregroundStyle(Palette.secondaryInk)
                    } else {
                        StorySection(viewModel: viewModel)
                        memories
                    }
                }
                .padding(Spacing.l)
            }
        }
        .ignoresSafeArea(edges: .top)
        .dsScreenBackground()
    }

    private var subtitle: String {
        let count = viewModel.entries.count
        let parts = [viewModel.trip.dateRangeText, "\(count) \(count == 1 ? "memory" : "memories")"] + viewModel.places.prefix(3)
        return parts.joined(separator: " · ")
    }

    private var memories: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(viewModel.days()) { day in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader("Day \(day.number) · \(day.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                    ForEach(day.entries) { entry in
                        RecentEntryRow(entry: entry, photoURL: viewModel.photoURL(for: entry))
                    }
                }
            }
        }
    }
}

private struct StorySection: View {
    let viewModel: TripDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if let story = viewModel.story {
                storyCard(story)
                ForEach(viewModel.highlights, id: \.entry.id) { item in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(item.highlight.caption)
                            .font(.dsMeta)
                            .foregroundStyle(Palette.secondaryInk)
                        RecentEntryRow(entry: item.entry, photoURL: viewModel.photoURL(for: item.entry))
                    }
                }
            } else {
                tellButton(title: "Tell the story")
            }
            if let failure = viewModel.storyFailure {
                StatusLabel(message(for: failure), systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func storyCard(_ story: TripStory) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(story.title)
                .font(.dsTitle)
                .foregroundStyle(Palette.ink)
            Text(story.text)
                .font(.dsBody)
                .foregroundStyle(Palette.ink)
            StatusLabel(writtenBy(story.writer), systemImage: story.writer == .onDevice ? "iphone" : "cloud")
            if !viewModel.storyIsCurrent {
                tellButton(title: "New memories since. Update the story")
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsSurface()
    }

    @ViewBuilder
    private func tellButton(title: String) -> some View {
        if viewModel.isWritingStory {
            HStack(spacing: Spacing.s) {
                ProgressView()
                Text("Writing your story \(viewModel.writer == .onDevice ? "on this iPhone" : "with Private Cloud Compute")…")
                    .font(.dsMeta)
                    .foregroundStyle(Palette.secondaryInk)
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Button(title) { Task { await viewModel.tellStory() } }
                    .buttonStyle(.dsPrimary)
                // Said before the tap, so the user knows where their notes go before they go anywhere.
                Text(viewModel.writer == .onDevice
                     ? "Written on this iPhone. Nothing leaves it."
                     : "Your notes are sent to Apple's Private Cloud Compute to write it.")
                    .font(.dsMeta)
                    .foregroundStyle(Palette.secondaryInk)
            }
        }
    }

    private func writtenBy(_ writer: TripStory.Writer) -> String {
        switch writer {
        case .onDevice: "Written on this iPhone"
        case .privateCloudCompute: "Written with Private Cloud Compute"
        }
    }

    private func message(for failure: TripStoryError) -> String {
        switch failure {
        case .tooLong: "This trip is too long to tell on this iPhone."
        case .notReady: "Apple Intelligence is busy or not ready. Try again in a moment."
        case .unsupportedLanguage: "Stories can only be written from English notes for now."
        case .declined: "Couldn't write a story for this trip."
        case .noEntries: "Add a memory first, then tell the story."
        case .unexpected: "Couldn't write the story this time."
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: PreviewTripRepository.sampleTrips[0], dependencies: .preview())
    }
}
