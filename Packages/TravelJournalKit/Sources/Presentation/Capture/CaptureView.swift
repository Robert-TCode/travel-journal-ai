import SwiftUI
import Domain

struct CaptureView: View {
    @State private var viewModel: CaptureViewModel
    @FocusState private var isEditingNote: Bool

    init(availabilityService: any AIModelAvailabilityService, repository: any EntryRepository) {
        _viewModel = State(initialValue: CaptureViewModel(
            availabilityService: availabilityService,
            repository: repository
        ))
    }

    var body: some View {
        NavigationStack {
            noteForm
                .navigationTitle("Capture")
        }
        .task { await viewModel.observeAvailability() }
    }

    /// Saving never depends on Apple Intelligence; availability only decides whether smart tags will follow.
    private var noteForm: some View {
        Form {
            if case .unavailable(let reason) = viewModel.availability {
                Section {
                    unavailableView(for: reason)
                }
            }

            Section("Note") {
                TextEditor(text: $viewModel.noteText)
                    .frame(minHeight: 120)
                    .focused($isEditingNote)
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
        }
    }

    private func unavailableView(for reason: AIModelAvailability.UnavailabilityReason) -> some View {
        let (title, systemImage, message) = switch reason {
        case .notEnabled:
            ("Smart tags are off", "apple.intelligence",
             "Your notes are saved. Turn on Apple Intelligence in Settings > Apple Intelligence & Siri to tag them automatically.")
        case .notReadyYet:
            ("Smart tags are getting ready", "arrow.down.circle",
             "Your notes are saved. Apple Intelligence is still downloading; tags will follow once it's ready.")
        case .notSupported:
            ("Smart tags aren't available", "iphone.slash",
             "Your notes are saved. This iPhone doesn't support Apple Intelligence, so notes won't be tagged automatically.")
        case .unknown:
            ("Smart tags are unavailable", "exclamationmark.triangle",
             "Your notes are saved. Tags will follow when Apple Intelligence is available again.")
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

#Preview("Available") {
    CaptureView(
        availabilityService: PreviewAvailabilityService(.available),
        repository: PreviewEntryRepository()
    )
}

#Preview("Not enabled") {
    CaptureView(
        availabilityService: PreviewAvailabilityService(.unavailable(reason: .notEnabled)),
        repository: PreviewEntryRepository()
    )
}

#Preview("Getting ready") {
    CaptureView(
        availabilityService: PreviewAvailabilityService(.unavailable(reason: .notReadyYet)),
        repository: PreviewEntryRepository()
    )
}

#Preview("Not supported") {
    CaptureView(
        availabilityService: PreviewAvailabilityService(.unavailable(reason: .notSupported)),
        repository: PreviewEntryRepository()
    )
}
