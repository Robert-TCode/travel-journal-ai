import SwiftUI
import Domain

struct CaptureView: View {
    @State private var viewModel: CaptureViewModel

    init(availabilityService: any AIModelAvailabilityService) {
        _viewModel = State(initialValue: CaptureViewModel(availabilityService: availabilityService))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Capture")
        }
        .task { await viewModel.observeAvailability() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.availability {
        case nil:
            ProgressView()
        case .available:
            ContentUnavailableView(
                "Nothing to capture yet",
                systemImage: "plus.circle",
                description: Text("Photos, voice notes and text will go here.")
            )
        case .unavailable(let reason):
            unavailableView(for: reason)
        }
    }

    private func unavailableView(for reason: AIModelAvailability.UnavailabilityReason) -> some View {
        let (title, systemImage, message) = switch reason {
        case .notEnabled:
            ("Turn on Apple Intelligence", "apple.intelligence",
             "Capture runs on your iPhone with Apple Intelligence. Turn it on in Settings > Apple Intelligence & Siri.")
        case .notReadyYet:
            ("Getting ready", "arrow.down.circle",
             "Apple Intelligence is still downloading. This screen updates by itself when it's ready.")
        case .notSupported:
            ("Not available on this iPhone", "iphone.slash",
             "Capture needs an iPhone that supports Apple Intelligence.")
        case .unknown:
            ("Apple Intelligence isn't available", "exclamationmark.triangle",
             "Try again in a moment.")
        }
        return ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

#Preview("Available") {
    CaptureView(availabilityService: PreviewAvailabilityService(.available))
}

#Preview("Not enabled") {
    CaptureView(availabilityService: PreviewAvailabilityService(.unavailable(reason: .notEnabled)))
}

#Preview("Getting ready") {
    CaptureView(availabilityService: PreviewAvailabilityService(.unavailable(reason: .notReadyYet)))
}

#Preview("Not supported") {
    CaptureView(availabilityService: PreviewAvailabilityService(.unavailable(reason: .notSupported)))
}
