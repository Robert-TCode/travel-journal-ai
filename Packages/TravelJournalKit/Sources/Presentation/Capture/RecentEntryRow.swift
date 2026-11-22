import SwiftUI
import Foundation
import Domain

struct RecentEntryRow: View {
    let entry: Entry
    var photoURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let photoURL {
                PhotoThumbnail(url: photoURL)
            }
            details
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.callout)
                    .lineLimit(3)
            }
            if let placeName = entry.placeName {
                Label(placeName, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            metadata
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var metadata: some View {
        switch entry.indexingStatus {
        case .pending:
            Label("Tagging…", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed:
            Label("Not tagged", systemImage: "tag.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .done:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.tint.opacity(0.12), in: Capsule())
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        RecentEntryRow(entry: Entry(tripID: UUID(), text: "Walked 20k steps today, my feet hurt.", tags: ["walking", "steps", "tired"], indexingStatus: .done))
        RecentEntryRow(entry: Entry(tripID: UUID(), text: "Black ice cream at Owakudani.", placeName: "Hakone, Kanagawa"))
        RecentEntryRow(entry: Entry(tripID: UUID(), text: "Bus leaves at 9.", indexingStatus: .failed))
    }
}
