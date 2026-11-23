import DesignSystem
import Domain
import Foundation

extension Sky {
    /// The sun's phase saved with the entry is exact (it comes from that place's sunrise and sunset).
    /// Without it, the capture time still gives an approximate phase, so even offline entries have a sky.
    /// Unknown weather is painted clear: a grey default would make most offline entries look dead.
    init(entry: Entry, calendar: Calendar = .current) {
        self.init(at: entry.createdAt, dayPhase: entry.dayPhase, weather: entry.weather, calendar: calendar)
    }

    init(at date: Date, dayPhase: DayPhase? = nil, weather: WeatherCondition? = nil, calendar: Calendar = .current) {
        self.init(
            phase: dayPhase.map(Phase.init) ?? Self.approximatePhase(at: date, calendar: calendar),
            condition: weather.map(Condition.init) ?? .clear
        )
    }

    /// The sky seen most often across the entries; ties go to the most recent one. Neutral when there are none.
    static func dominant(in entries: [Entry], calendar: Calendar = .current) -> Sky {
        let skies = entries
            .sorted { $0.createdAt > $1.createdAt }
            .map { Sky(entry: $0, calendar: calendar) }
        let counts = skies.reduce(into: [Sky: Int]()) { $0[$1, default: 0] += 1 }
        return skies.max { counts[$0, default: 0] < counts[$1, default: 0] } ?? .unknown
    }

    private static func approximatePhase(at date: Date, calendar: Calendar) -> Phase {
        switch calendar.component(.hour, from: date) {
        case 5..<7: .dawn
        case 7..<17: .day
        case 17..<19: .goldenHour
        case 19..<21: .dusk
        default: .night
        }
    }
}

private extension Sky.Phase {
    init(_ phase: DayPhase) {
        switch phase {
        case .dawn: self = .dawn
        case .day: self = .day
        case .goldenHour: self = .goldenHour
        case .dusk: self = .dusk
        case .night: self = .night
        }
    }
}

private extension Sky.Condition {
    init(_ weather: WeatherCondition) {
        switch weather {
        case .clear, .windy: self = .clear
        case .cloudy: self = .cloudy
        case .rainy, .snowy: self = .wet
        case .stormy, .foggy: self = .heavy
        }
    }
}
