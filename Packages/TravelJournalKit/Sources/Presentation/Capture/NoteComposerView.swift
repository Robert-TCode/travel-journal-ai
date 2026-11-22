import SwiftUI
import Domain

/// Saving never depends on Apple Intelligence; availability only decides whether smart tags will follow.
struct NoteComposerView: View {
    @Bindable var viewModel: CaptureViewModel
    let trip: Trip
    @FocusState private var isEditingNote: Bool
    @State private var isRecordingVoice = false

    var body: some View {
        Form {
            if case .unavailable(let reason) = viewModel.availability {
                Section {
                    SmartTagsUnavailableBanner(reason: reason)
                }
            }

            Section {
                NoteEditor(
                    text: $viewModel.noteText,
                    placeholder: viewModel.pendingPhotos.isEmpty ? "What happened?" : "Add a caption (optional)",
                    isFocused: $isEditingNote
                )
                if !viewModel.pendingPhotos.isEmpty {
                    PendingPhotosStrip(photos: viewModel.pendingPhotos, onRemove: viewModel.removePhoto)
                }
                CaptureActionButtons(
                    onPhoto: { data in await viewModel.addPhoto(data) },
                    onVoice: { isRecordingVoice = true }
                )
            } header: {
                Text("\(trip.name) · day \(viewModel.dayNumber(of: trip))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .textCase(nil)
            }

            Section {
                saveButton
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
                        RecentEntryRow(entry: entry, photoURL: viewModel.photoURL(for: entry))
                    }
                }
            }
        }
        .sheet(isPresented: $isRecordingVoice) {
            VoiceRecorderView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }

    private var saveButton: some View {
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
    }
}
