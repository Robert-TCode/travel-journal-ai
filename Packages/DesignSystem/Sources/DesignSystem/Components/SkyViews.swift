import SwiftUI

/// A card painted with a sky. Content inherits the sky's text color.
public struct SkyCard<Content: View>: View {
    let sky: Sky
    let content: Content

    public init(sky: Sky, @ViewBuilder content: () -> Content) {
        self.sky = sky
        self.content = content()
    }

    public var body: some View {
        content
            .foregroundStyle(sky.foreground)
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sky.gradient, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// The sky of a memory with no photo, shown where a thumbnail would be.
public struct SkyThumbnail: View {
    let sky: Sky
    var size: CGFloat

    public init(sky: Sky, size: CGFloat = 44) {
        self.sky = sky
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: Radius.thumbnail, style: .continuous)
            .fill(sky.gradient)
            .frame(width: size, height: size)
    }
}

/// The top of a screen painted with a sky: title, a line of meta, and an optional trailing action.
public struct SkyHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let sky: Sky
    /// Extra room above the title, for a screen that draws the header under its navigation bar.
    let topInset: CGFloat
    let trailing: Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        sky: Sky,
        topInset: CGFloat = 0,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.sky = sky
        self.topInset = topInset
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.dsDisplay)
                Spacer()
                trailing
            }
            if let subtitle {
                Text(subtitle)
                    .font(.dsMeta)
                    .opacity(0.85)
            }
        }
        .foregroundStyle(sky.foreground)
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.m + topInset)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sky.gradient.ignoresSafeArea(edges: .top))
    }
}
