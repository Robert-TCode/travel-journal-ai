import DesignSystem
import Domain
import SwiftUI

/// Saving never depends on Apple Intelligence; availability only decides whether smart tags will follow.
struct NoteComposerView: View {
    @Bindable var viewModel: CaptureViewModel
    let trip: Trip
    let onEndTrip: () -> Void
    @FocusState private var isEditingNote: Bool
    @State private var isRecordingVoice = false

    /// The header wears the sky of the latest memory, or of this hour before the first one.
    private var sky: Sky {
        viewModel.recentEntries.first.map { Sky(entry: $0) } ?? Sky(at: .now)
    }

    var body: some View {
        VStack(spacing: 0) {
            SkyHeader(title: trip.name, subtitle: subtitle, sky: sky) {
                Button("End trip", action: onEndTrip)
                    .buttonStyle(.dsTextAction(on: sky))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    if case .unavailable(let reason) = viewModel.availability {
                        SmartTagsUnavailableBanner(reason: reason)
                    }
                    composer
                    saveStatus
                    if !viewModel.recentEntries.isEmpty {
                        recent
                    }
                }
                .padding(Spacing.l)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.default, value: sky)
        .sheet(isPresented: $isRecordingVoice) {
            VoiceRecorderView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }

    private var subtitle: String {
        let day = "Day \(viewModel.dayNumber(of: trip))"
        guard let place = viewModel.recentEntries.first?.placeName else { return day }
        return "\(day) · \(place)"
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            NoteEditor(
                text: $viewModel.noteText,
                placeholder: viewModel.pendingPhotos.isEmpty ? "What happened?" : "Add a caption (optional)",
                isFocused: $isEditingNote
            )
            if !viewModel.pendingPhotos.isEmpty {
                PendingPhotosStrip(photos: viewModel.pendingPhotos, onRemove: viewModel.removePhoto)
            }
            HStack(spacing: Spacing.s) {
                CaptureActionButtons(
                    onPhoto: { data in await viewModel.addPhoto(data) },
                    onVoice: { isRecordingVoice = true }
                )
                Spacer()
                saveButton
            }
        }
        .padding(Spacing.m)
        .dsSurface()
    }

    private var saveButton: some View {
        Button {
            // A focused TextEditor can write its text back after we clear it; end editing first.
            isEditingNote = false
            Task { await viewModel.save() }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .tint(Palette.onInk)
            } else {
                Text("Save")
            }
        }
        .buttonStyle(.dsPrimary)
        .disabled(!viewModel.canSave)
    }

    @ViewBuilder
    private var saveStatus: some View {
        if viewModel.didSave {
            StatusLabel("Saved. Tags will follow.", systemImage: "checkmark.circle")
        } else if viewModel.recordingTooShort {
            StatusLabel("Too short to save. Speak a little longer.", systemImage: "waveform.slash")
        } else if viewModel.saveFailed {
            StatusLabel("Couldn't save. Try again.", systemImage: "exclamationmark.triangle")
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Recent")
            ForEach(viewModel.recentEntries) { entry in
                RecentEntryRow(entry: viewModel.displayed(entry), photoURL: viewModel.photoURL(for: entry))
            }
        }
    }
}
