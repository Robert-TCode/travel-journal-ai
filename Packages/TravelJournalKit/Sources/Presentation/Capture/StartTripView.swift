import SwiftUI

struct StartTripView: View {
    @Bindable var viewModel: CaptureViewModel

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Going somewhere?")
                .font(.title3.weight(.semibold))
            Text("Start a trip and every memory lands in it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Trip name, e.g. Japan", text: $viewModel.tripNameDraft)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.go)
                .onSubmit { Task { await viewModel.startTrip() } }

            Button {
                Task { await viewModel.startTrip() }
            } label: {
                Text("Start trip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!viewModel.canStartTrip)

            if viewModel.startTripFailed {
                Text("Couldn't start the trip. Try again.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .task { await viewModel.suggestTripName() }
    }
}
