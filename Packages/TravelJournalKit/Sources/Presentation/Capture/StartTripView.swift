import DesignSystem
import SwiftUI

struct StartTripView: View {
    @Bindable var viewModel: CaptureViewModel

    var body: some View {
        EmptyStateView(
            systemImage: "suitcase.rolling",
            title: "Going somewhere?",
            message: "Start a trip and every memory lands in it."
        ) {
            VStack(spacing: Spacing.m) {
                TextField("Trip name, e.g. Japan", text: $viewModel.tripNameDraft)
                    .font(.dsBody)
                    .foregroundStyle(Palette.ink)
                    .submitLabel(.go)
                    .onSubmit { Task { await viewModel.startTrip() } }
                    .padding(Spacing.m)
                    .dsSurface()

                Button {
                    Task { await viewModel.startTrip() }
                } label: {
                    Text("Start trip")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.dsPrimary)
                .disabled(!viewModel.canStartTrip)

                if viewModel.startTripFailed {
                    StatusLabel("Couldn't start the trip. Try again.", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .task { await viewModel.suggestTripName() }
    }
}
