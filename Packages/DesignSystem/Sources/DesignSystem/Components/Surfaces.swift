import SwiftUI

public extension View {
    /// The cream card that holds text fields and memory rows.
    func dsSurface(cornerRadius: CGFloat = Radius.field) -> some View {
        background(Palette.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.08), radius: 2, y: 1)
    }

    /// The warm page behind every screen.
    func dsScreenBackground() -> some View {
        background(Palette.background.ignoresSafeArea())
    }
}

/// One clear next step: icon on a small sky, a title, a sentence, and the action.
public struct EmptyStateView<Actions: View>: View {
    let systemImage: String
    let sky: Sky
    let title: String
    let message: String
    let actions: Actions

    public init(
        systemImage: String,
        sky: Sky = Sky(phase: .goldenHour, condition: .clear),
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.systemImage = systemImage
        self.sky = sky
        self.title = title
        self.message = message
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(sky.foreground)
                .frame(width: 72, height: 72)
                .background(sky.gradient, in: Circle())
            Text(title)
                .font(.dsTitle)
                .foregroundStyle(Palette.ink)
            Text(message)
                .font(.dsBody)
                .foregroundStyle(Palette.secondaryInk)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, Spacing.s)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 420)
    }
}
