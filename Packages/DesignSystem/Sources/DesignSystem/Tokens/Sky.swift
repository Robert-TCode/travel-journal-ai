import SwiftUI

/// The color of a moment: phase of the day × how the weather looked. The app's only source of color.
/// Each sky picks its own text color, checked for contrast against every stop.
public struct Sky: Sendable, Hashable {
    public enum Phase: String, Sendable, CaseIterable {
        case dawn, day, goldenHour, dusk, night
    }

    /// Weather grouped by how it changes the light, not by meteorology.
    public enum Condition: String, Sendable, CaseIterable {
        case clear      // clear, windy
        case cloudy
        case wet        // rain, snow
        case heavy      // storm, fog
    }

    public let phase: Phase?
    public let condition: Condition

    public init(phase: Phase?, condition: Condition) {
        self.phase = phase
        self.condition = condition
    }

    /// No time or weather known: a warm neutral, never a guess.
    public static let unknown = Sky(phase: nil, condition: .clear)

    public static var all: [Sky] {
        Phase.allCases.flatMap { phase in Condition.allCases.map { Sky(phase: phase, condition: $0) } } + [.unknown]
    }

    public var stops: [RGB] { palette.stops.map(RGB.init(hex:)) }
    public var foregroundRGB: RGB { RGB(hex: palette.foreground) }
    public var foreground: Color { foregroundRGB.color }
    public var isDark: Bool { foregroundRGB.luminance > 0.5 }

    /// Top-leading to bottom: the darker part of the sky sits up, where a real sky darkens.
    public var gradient: LinearGradient {
        LinearGradient(colors: stops.map(\.color), startPoint: .topLeading, endPoint: .bottom)
    }

    private var palette: (stops: [UInt32], foreground: UInt32) {
        let white: UInt32 = 0xFFFFFF
        switch (phase, condition) {
        case (nil, _): return ([0xE7E1DA, 0xF5F1EC], 0x2A221D)

        case (.dawn, .clear): return ([0x9A93C4, 0xDDA6BC, 0xF6CCA8], 0x2E2638)
        case (.dawn, .cloudy): return ([0x7D7895, 0xC9A9B6, 0xE8D3C6], 0x2E2638)
        case (.dawn, .wet): return ([0xA6A6B8, 0xC4BDC6, 0xDCD3D1], 0x2E2638)
        case (.dawn, .heavy): return ([0x4D4B63, 0x8B8296], white)

        case (.day, .clear): return ([0x8CC3EC, 0xDCEEFA], 0x12324A)
        case (.day, .cloudy): return ([0xC3CFDA, 0xEEF1F3], 0x22313D)
        case (.day, .wet): return ([0x8D9AA8, 0xC4CCD3], 0x152029)
        case (.day, .heavy): return ([0x565B73, 0x7E8197], white)

        case (.goldenHour, .clear): return ([0xF2B35E, 0xF08A4B, 0xE5674A], 0x3A1A0C)
        case (.goldenHour, .cloudy): return ([0xE8B98A, 0xD99A86, 0xB7A0B5], 0x3A1F1A)
        case (.goldenHour, .wet): return ([0xD8B79F, 0xB6ABB5], 0x2E1F1A)
        case (.goldenHour, .heavy): return ([0x8E6A63, 0x5E5670], white)

        case (.dusk, .clear): return ([0x2C2A5E, 0x7A4A86, 0xC4524F, 0xD06A45], white)
        case (.dusk, .cloudy): return ([0x3E3A66, 0x8B5E8E, 0xB0656F], white)
        case (.dusk, .wet): return ([0x33334F, 0x6C5A78], white)
        case (.dusk, .heavy): return ([0x211D3A, 0x4E3A5E], white)

        case (.night, .clear): return ([0x0F1636, 0x2B2F63], white)
        case (.night, .cloudy): return ([0x1F2233, 0x3D3F55], white)
        case (.night, .wet): return ([0x1A2029, 0x343C49], white)
        case (.night, .heavy): return ([0x16132A, 0x352B4E], white)
        }
    }
}

extension Sky: CustomStringConvertible {
    public var description: String {
        phase.map { "\($0.rawValue) \(condition.rawValue)" } ?? "unknown"
    }
}
