import SwiftUI

struct VoiceRecorderView: View {
    @Bindable var viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.microphoneDenied {
                ContentUnavailableView(
                    "Microphone is off",
                    systemImage: "mic.slash",
                    description: Text("Allow microphone access for Travel Journal in Settings to record voice notes.")
                )
                Button("Close") { dismiss() }
            } else {
                Spacer()
                Image(systemName: "mic.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.purple)
                    .frame(width: 80, height: 80)
                    .background(.purple.opacity(0.12), in: Circle())
                    .symbolEffect(.pulse, isActive: viewModel.recordingStartedAt != nil)
                elapsedTime
                Text("Speak freely. It's saved as audio and transcribed on your iPhone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                HStack(spacing: 12) {
                    Button(role: .cancel) {
                        Task { await viewModel.cancelRecording() }
                        dismiss()
                    } label: {
                        Text("Cancel").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task {
                            await viewModel.finishRecording()
                            dismiss()
                        }
                    } label: {
                        Text("Save").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(viewModel.recordingStartedAt == nil)
                }
            }
        }
        .padding(24)
        .task { await viewModel.startRecording() }
        .interactiveDismissDisabled(viewModel.recordingStartedAt != nil)
    }

    private var elapsedTime: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let seconds = Int(context.date.timeIntervalSince(viewModel.recordingStartedAt ?? context.date))
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.title2.monospacedDigit().weight(.medium))
        }
    }
}
