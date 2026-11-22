import SwiftUI
import Domain
import Foundation

struct CaptureView: View {
    @State private var viewModel: CaptureViewModel
    @State private var isConfirmingEnd = false
    @FocusState private var isEditingNote: Bool

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
            noteForm(for: trip)
        } else {
            StartTripView(viewModel: viewModel)
        }
    }

    /// Saving never depends on Apple Intelligence; availability only decides whether smart tags will follow.
    private func noteForm(for trip: Trip) -> some View {
        Form {
            if case .unavailable(let reason) = viewModel.availability {
                Section {
                    unavailableView(for: reason)
                }
            }

            Section {
                TextEditor(text: $viewModel.noteText)
                    .font(.callout)
                    .frame(minHeight: 110)
                    .focused($isEditingNote)
                    .overlay(alignment: .topLeading) {
                        if viewModel.noteText.isEmpty {
                            Text("What happened?")
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("\(trip.name) · day \(viewModel.dayNumber(of: trip))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .textCase(nil)
            }

            Section {
                Button {
                    // A focused TextEditor can write its text back after we clear it; end editing first.
                    isEditingNote = false
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!viewModel.canSave)
            } footer: {
                if viewModel.didSave {
                    Label("Saved", systemImage: "checkmark.circle")
                } else if viewModel.saveFailed {
                    Label("Couldn't save. Try again.", systemImage: "exclamationmark.triangle")
                }
            }

            if !viewModel.recentEntries.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentEntries) { entry in
                        RecentEntryRow(entry: entry)
                    }
                }
            }
        }
    }

    private func unavailableView(for reason: AIModelAvailability.UnavailabilityReason) -> some View {
        let (title, systemImage, message) = switch reason {
        case .notEnabled:
            ("Smart tags are off", "apple.intelligence",
             "Notes still save. Turn on Apple Intelligence in Settings > Apple Intelligence & Siri to tag them automatically.")
        case .notReadyYet:
            ("Smart tags are getting ready", "arrow.down.circle",
             "Notes still save. Apple Intelligence is still downloading; tags will follow once it's ready.")
        case .notSupported:
            ("Smart tags aren't available", "iphone.slash",
             "Notes still save. This iPhone doesn't support Apple Intelligence, so notes won't be tagged automatically.")
        case .unknown:
            ("Smart tags are unavailable", "exclamationmark.triangle",
             "Notes still save. Tags will follow when Apple Intelligence is available again.")
        }
        return VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
