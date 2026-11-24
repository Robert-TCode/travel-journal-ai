import DesignSystem
import Domain
import SwiftUI

struct TripCard: View {
    let summary: TripSummary
    let sky: Sky

    private var trip: Trip { summary.trip }

    var body: some View {
        SkyCard(sky: sky) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(trip.name)
                        .font(.dsDisplay)
                    Spacer()
                    if trip.isOngoing {
                        SkyChip("Now", sky: sky)
                    }
                }
                Text("\(trip.dateRangeText) · \(summary.memoryCount) \(summary.memoryCount == 1 ? "memory" : "memories")")
                    .font(.dsMeta)
                    .opacity(0.85)
                if !summary.topTags.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(summary.topTags, id: \.self) { SkyChip($0, sky: sky) }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
    }
}

/// A tag on a sky: tinted with the sky's own text color, so it works on light and dark skies alike.
private struct SkyChip: View {
    let text: String
    let sky: Sky

    init(_ text: String, sky: Sky) {
        self.text = text
        self.sky = sky
    }

    var body: some View {
        Text(text)
            .font(.dsMeta)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 3)
            .background(sky.foreground.opacity(0.14), in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        TripCard(
            summary: TripSummary(trip: Trip(name: "Japan"), memoryCount: 14, topTags: ["ramen", "onsen", "hiking"]),
            sky: Sky(phase: .goldenHour, condition: .clear)
        )
        TripCard(
            summary: TripSummary(trip: Trip(name: "Norway", endedAt: .now), memoryCount: 1, topTags: ["fjord"]),
            sky: Sky(phase: .night, condition: .clear)
        )
        TripCard(summary: TripSummary(trip: Trip(name: "Lisbon", endedAt: .now), memoryCount: 0, topTags: []), sky: .unknown)
    }
    .padding()
    .dsScreenBackground()
}
