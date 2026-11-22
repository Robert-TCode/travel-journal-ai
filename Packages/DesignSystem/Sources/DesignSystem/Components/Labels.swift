import SwiftUI

public struct TagChip: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.dsMeta)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 3)
            .background(Palette.fill, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }
}

/// Mood is text, not a colored badge: the sky already carries the emotion.
public struct MoodLabel: View {
    let mood: String

    public init(_ mood: String) {
        self.mood = mood
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(Palette.accent)
                .frame(width: 5, height: 5)
            Text(mood)
        }
        .font(.dsMeta)
        .foregroundStyle(Palette.secondaryInk)
    }
}

/// Small, quiet states such as "Tagging…", "Not tagged" or "Voice note".
public struct StatusLabel: View {
    let text: String
    let systemImage: String

    public init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        Label(text, systemImage: systemImage)
            .font(.dsMeta)
            .foregroundStyle(Palette.secondaryInk)
    }
}

public struct SectionHeader: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .dsSectionLabel()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
