import Foundation

/// Where the sun was when an entry was captured. Stored as a raw value.
public enum DayPhase: String, Sendable, Equatable, CaseIterable {
    case dawn
    case day
    case goldenHour
    case dusk
    case night

    /// Bands around the real sunrise and sunset of that place and day, so a December afternoon in Norway
    /// and a June evening in Lisbon both get the light they actually had.
    public init(at date: Date, sunrise: Date, sunset: Date) {
        let minute: TimeInterval = 60
        switch date {
        case sunrise.addingTimeInterval(-40 * minute)..<sunrise.addingTimeInterval(20 * minute): self = .dawn
        case sunrise.addingTimeInterval(20 * minute)..<sunset.addingTimeInterval(-60 * minute): self = .day
        case sunset.addingTimeInterval(-60 * minute)..<sunset: self = .goldenHour
        case sunset..<sunset.addingTimeInterval(40 * minute): self = .dusk
        default: self = .night
        }
    }
}
