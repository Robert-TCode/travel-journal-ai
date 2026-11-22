import SwiftUI

/// Five styles, built on text styles so Dynamic Type still scales them.
public extension Font {
    /// 28 bold: trip names.
    static let dsDisplay = Font.title.bold()
    /// 17 semibold: screen and card titles.
    static let dsTitle = Font.headline
    /// 15 regular: what the user wrote.
    static let dsBody = Font.subheadline
    /// 12 medium: dates, places, weather.
    static let dsMeta = Font.caption.weight(.medium)
    /// 11 semibold: section labels, shown in caps.
    static let dsSection = Font.caption2.weight(.semibold)
}

public extension View {
    func dsSectionLabel() -> some View {
        font(.dsSection)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(Palette.secondaryInk)
    }
}
