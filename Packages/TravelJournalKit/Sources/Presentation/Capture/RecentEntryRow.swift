import SwiftUI
import Domain

/// A saved entry with its tags shown discreetly. Tags appear on their own once indexing finishes.
struct RecentEntryRow: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.text)
                .lineLimit(3)
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
        RecentEntryRow(entry: Entry(tripID: UUID(), text: "Black ice cream at Owakudani."))
        RecentEntryRow(entry: Entry(tripID: UUID(), text: "Bus leaves at 9.", indexingStatus: .failed))
    }
}
