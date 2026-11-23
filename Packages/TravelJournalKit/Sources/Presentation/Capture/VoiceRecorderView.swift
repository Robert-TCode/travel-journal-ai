import DesignSystem
import SwiftUI

struct VoiceRecorderView: View {
    @Bindable var viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.microphoneDenied {
                EmptyStateView(
                    systemImage: "mic.slash",
                    sky: .unknown,
                    title: "Microphone is off",
                    message: "Allow microphone access for Travel Journal in Settings to record voice notes."
                ) {
                    Button("Close") { dismiss() }
                        .buttonStyle(.dsSecondary)
                }
            } else {
                recorder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsScreenBackground()
        .task { await viewModel.startRecording() }
        .interactiveDismissDisabled(viewModel.recordingStartedAt != nil)
    }

    private var recorder: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Palette.onInk)
                .frame(width: 72, height: 72)
                .background(Palette.ink, in: Circle())
                .symbolEffect(.variableColor.iterative, isActive: viewModel.recordingStartedAt != nil)
            elapsedTime
            Text("Speak freely. It's saved as audio and transcribed on your iPhone.")
                .font(.dsMeta)
                .foregroundStyle(Palette.secondaryInk)
                .multilineTextAlignment(.center)
            Spacer()
            HStack(spacing: Spacing.m) {
                Button {
                    Task { await viewModel.cancelRecording() }
                    dismiss()
                } label: {
                    Text("Cancel").frame(maxWidth: .infinity)
                }
                .buttonStyle(.dsSecondary)

                Button {
                    Task {
                        await viewModel.finishRecording()
                        dismiss()
                    }
                } label: {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.dsPrimary)
                .disabled(viewModel.recordingStartedAt == nil)
            }
        }
        .padding(Spacing.xl)
    }

    private var elapsedTime: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let seconds = Int(context.date.timeIntervalSince(viewModel.recordingStartedAt ?? context.date))
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.dsDisplay.monospacedDigit())
                .foregroundStyle(Palette.ink)
        }
    }
}
