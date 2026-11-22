import SwiftUI

/// The one filled action on a screen. On a sky it inverts the sky's own colors, so it never clashes.
public struct PrimaryButtonStyle: ButtonStyle {
    let sky: Sky?
    @Environment(\.isEnabled) private var isEnabled

    public init(on sky: Sky? = nil) {
        self.sky = sky
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsTitle)
            .foregroundStyle(sky.map { $0.stops[0].color } ?? Palette.onInk)
            .padding(.vertical, Spacing.m)
            .padding(.horizontal, Spacing.xl)
            .background(sky.map(\.foreground) ?? Palette.ink, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    let sky: Sky?
    @Environment(\.isEnabled) private var isEnabled

    public init(on sky: Sky? = nil) {
        self.sky = sky
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsTitle)
            .foregroundStyle(sky?.foreground ?? Palette.ink)
            .padding(.vertical, Spacing.m)
            .padding(.horizontal, Spacing.xl)
            .background(sky.map { $0.foreground.opacity(0.18) } ?? Palette.fill, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
    }
}

/// A 44 pt round tool: camera, library, voice. Quiet on purpose; the primary action stays the loudest.
public struct IconActionButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .labelStyle(.iconOnly)
            .foregroundStyle(isSelected ? Palette.onInk : Palette.ink)
            .frame(width: Size.iconAction, height: Size.iconAction)
            .background(isSelected ? Palette.ink : Palette.fill, in: Circle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .contentShape(Circle())
    }
}

/// For secondary navigation-like actions such as "End trip".
public struct TextActionButtonStyle: ButtonStyle {
    let sky: Sky?

    public init(on sky: Sky? = nil) {
        self.sky = sky
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(sky?.foreground ?? Palette.accent)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var dsPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func dsPrimary(on sky: Sky) -> PrimaryButtonStyle { PrimaryButtonStyle(on: sky) }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var dsSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func dsSecondary(on sky: Sky) -> SecondaryButtonStyle { SecondaryButtonStyle(on: sky) }
}

public extension ButtonStyle where Self == IconActionButtonStyle {
    static var dsIconAction: IconActionButtonStyle { IconActionButtonStyle() }
    static func dsIconAction(selected: Bool) -> IconActionButtonStyle { IconActionButtonStyle(isSelected: selected) }
}

public extension ButtonStyle where Self == TextActionButtonStyle {
    static var dsTextAction: TextActionButtonStyle { TextActionButtonStyle() }
    static func dsTextAction(on sky: Sky) -> TextActionButtonStyle { TextActionButtonStyle(on: sky) }
}
