import SwiftUI
import Domain

struct SmartTagsUnavailableBanner: View {
    let reason: AIModelAvailability.UnavailabilityReason

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(content.title, systemImage: content.systemImage)
                .font(.headline)
            Text(content.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var content: (title: String, systemImage: String, message: String) {
        switch reason {
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
    }
}
