import SwiftUI

/// Every token and component in one scrollable page, for reviewing the system as a whole.
public struct DesignSystemCatalog: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                skies
                typography
                buttons
                labels
                cards
                EmptyStateView(
                    systemImage: "safari",
                    title: "Going somewhere?",
                    message: "Start a trip and every memory lands in it, tinted by the sky you saw."
                ) {
                    Button("Start trip") {}
                        .buttonStyle(.dsPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Spacing.l)
        }
        .dsScreenBackground()
    }

    private var skies: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Skies")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(Sky.all, id: \.self) { sky in
                    Text(name(of: sky))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(sky.foreground)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .bottomLeading)
                        .padding(6)
                        .background(sky.gradient, in: RoundedRectangle(cornerRadius: Radius.thumbnail, style: .continuous))
                }
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Type")
            Text("Japan").font(.dsDisplay)
            Text("Day 3 in Kyoto").font(.dsTitle)
            Text("Best ramen of my life, tiny place near the station.").font(.dsBody)
            Text("Kyoto · 18° clear · 7:40 PM").font(.dsMeta).foregroundStyle(Palette.secondaryInk)
        }
        .foregroundStyle(Palette.ink)
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Buttons")
            HStack {
                Button("Save memory") {}.buttonStyle(.dsPrimary)
                Button("Save") {}.buttonStyle(.dsPrimary).disabled(true)
            }
            Button("Start a new trip") {}.buttonStyle(.dsSecondary)
            HStack(spacing: Spacing.m) {
                Button("Camera", systemImage: "camera") {}.buttonStyle(.dsIconAction)
                Button("Photos", systemImage: "photo.on.rectangle") {}.buttonStyle(.dsIconAction)
                Button("Voice", systemImage: "mic") {}.buttonStyle(.dsIconAction)
                Button("Bike", systemImage: "bicycle") {}.buttonStyle(.dsIconAction(selected: true))
                Spacer()
                Button("End trip") {}.buttonStyle(.dsTextAction)
            }
            let dusk = Sky(phase: .dusk, condition: .clear)
            HStack {
                Button("Save memory") {}.buttonStyle(.dsPrimary(on: dusk))
                Button("Later") {}.buttonStyle(.dsSecondary(on: dusk))
                Spacer()
                Button("End trip") {}.buttonStyle(.dsTextAction(on: dusk))
            }
            .padding(Spacing.l)
            .background(dusk.gradient, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Tags and states")
            HStack {
                TagChip("ramen")
                TagChip("onsen")
                TagChip("hiking")
                MoodLabel("amazed")
            }
            HStack(spacing: Spacing.l) {
                StatusLabel("Tagging…", systemImage: "sparkles")
                StatusLabel("Not tagged", systemImage: "tag.slash")
                StatusLabel("Voice note", systemImage: "waveform")
            }
        }
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Cards")
            SkyCard(sky: Sky(phase: .dusk, condition: .clear)) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Image(systemName: "bus")
                    Text("Transylvania").font(.dsDisplay)
                    Text("Since Nov 20 · 14 memories · castles, forest").font(.dsMeta).opacity(0.85)
                }
            }
            SkyCard(sky: Sky(phase: .goldenHour, condition: .clear)) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Image(systemName: "bicycle")
                    Text("Tuscany").font(.dsTitle)
                    Text("May 3 – 12 · 22 memories").font(.dsMeta).opacity(0.85)
                }
            }
            HStack(spacing: Spacing.m) {
                SkyThumbnail(sky: Sky(phase: .night, condition: .clear))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bonfire after the hike").font(.dsBody).foregroundStyle(Palette.ink)
                    Text("6:10 PM · bonfire · friends").font(.dsMeta).foregroundStyle(Palette.secondaryInk)
                }
                Spacer()
            }
            .padding(Spacing.s)
            .dsSurface()
        }
    }

    private func name(of sky: Sky) -> String {
        guard let phase = sky.phase else { return "unknown" }
        return "\(phase.rawValue)\n\(sky.condition.rawValue)"
    }
}

#Preview("Light") {
    DesignSystemCatalog()
}

#Preview("Dark") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}
