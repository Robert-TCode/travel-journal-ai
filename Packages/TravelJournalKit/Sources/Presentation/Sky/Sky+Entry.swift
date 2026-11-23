import DesignSystem
import Domain
import Foundation

extension Sky {
    /// The capture time is always known, so every entry has a sky, even offline or without location.
    /// Clock bands give the phase; Open-Meteo's day/night, when present, corrects them (winter dusk at 16:00,
    /// summer light at 22:00). Unknown weather is painted clear: a grey default would make most offline entries look dead.
    init(entry: Entry, calendar: Calendar = .current) {
        self.init(at: entry.createdAt, isDaytime: entry.isDaytime, weather: entry.weather, calendar: calendar)
    }

    init(at date: Date, isDaytime: Bool? = nil, weather: WeatherCondition? = nil, calendar: Calendar = .current) {
        self.init(
            phase: Self.phase(at: date, isDaytime: isDaytime, calendar: calendar),
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

    private static func phase(at date: Date, isDaytime: Bool?, calendar: Calendar) -> Phase {
        let byClock: Phase = switch calendar.component(.hour, from: date) {
        case 5..<7: .dawn
        case 7..<17: .day
        case 17..<19: .goldenHour
        case 19..<21: .dusk
        default: .night
        }
        switch (byClock, isDaytime) {
        case (.day, false), (.goldenHour, false): return .night
        case (.dusk, true): return .goldenHour
        case (.night, true): return .day
        default: return byClock
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
