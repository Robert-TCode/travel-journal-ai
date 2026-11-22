import SwiftUI
import UIKit

/// Warm neutrals: everything except the skies. Color is reserved for meaning;
/// the accent appears at most once per screen.
public enum Palette {
    public static let background = Color(light: 0xF6F2ED, dark: 0x15120F)
    public static let surface = Color(light: 0xFFFDFA, dark: 0x1F1B17)
    public static let fill = Color(light: 0xEFE9E2, dark: 0x2B2621)
    public static let ink = Color(light: 0x2A221D, dark: 0xF5EFE8)
    public static let secondaryInk = Color(light: 0x6F645B, dark: 0xA3978C)
    public static let onInk = Color(light: 0xFBF7F2, dark: 0x1A1613)
    public static let accent = Color(light: 0xB04A2A, dark: 0xE4774F)
    public static let separator = Color(light: 0xE3DCD3, dark: 0x332D27)

    /// Light-mode values, for contrast checks.
    public enum Light {
        public static let background = RGB(hex: 0xF6F2ED)
        public static let surface = RGB(hex: 0xFFFDFA)
        public static let ink = RGB(hex: 0x2A221D)
        public static let secondaryInk = RGB(hex: 0x6F645B)
        public static let onInk = RGB(hex: 0xFBF7F2)
        public static let accent = RGB(hex: 0xB04A2A)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let rgb = RGB(hex: traits.userInterfaceStyle == .dark ? dark : light)
            return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        })
    }
}
