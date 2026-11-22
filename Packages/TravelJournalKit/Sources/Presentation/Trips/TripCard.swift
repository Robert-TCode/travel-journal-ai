import SwiftUI
import Domain

struct TripCard: View {
    let summary: TripSummary

    private var trip: Trip { summary.trip }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(trip.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                if trip.isOngoing {
                    Text("Now")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.7), in: Capsule())
                }
            }

            Text("\(dateRange) · \(summary.memoryCount) \(summary.memoryCount == 1 ? "memory" : "memories")")
                .font(.footnote)
                .opacity(0.8)

            if !summary.topTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(summary.topTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.55), in: Capsule())
                    }
                }
            }
        }
        .foregroundStyle(palette.ink)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.fill.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dateRange: String {
        let start = trip.startedAt.formatted(.dateTime.month(.abbreviated).day())
        guard let end = trip.endedAt else { return "Since \(start)" }
        return "\(start) – \(end.formatted(.dateTime.month(.abbreviated).day().year()))"
    }

    /// Stable per trip: derived from the id, not the list position, so a card keeps its color.
    private var palette: (fill: Color, ink: Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.98, green: 0.86, blue: 0.80), Color(red: 0.45, green: 0.17, blue: 0.07)),
            (Color(red: 0.84, green: 0.94, blue: 0.89), Color(red: 0.03, green: 0.31, blue: 0.25)),
            (Color(red: 0.86, green: 0.91, blue: 0.98), Color(red: 0.05, green: 0.27, blue: 0.49)),
            (Color(red: 0.91, green: 0.89, blue: 0.99), Color(red: 0.24, green: 0.20, blue: 0.54)),
            (Color(red: 0.99, green: 0.93, blue: 0.82), Color(red: 0.39, green: 0.22, blue: 0.02)),
        ]
        let index = Int(trip.id.uuid.0) % palettes.count
        return palettes[index]
    }
}

#Preview {
    VStack {
        TripCard(summary: TripSummary(trip: Trip(name: "Japan"), memoryCount: 14, topTags: ["ramen", "onsen", "hiking"]))
        TripCard(summary: TripSummary(trip: Trip(name: "Norway", endedAt: .now), memoryCount: 1, topTags: []))
    }
    .padding()
}
