import DesignSystem
import Domain
import Foundation
import Testing
@testable import Presentation

@Suite("Sky from entries")
struct SkyEntryTests {
    /// A fixed time zone, so the hour bands don't depend on where the tests run.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test(arguments: [
        (WeatherCondition.clear, Sky.Condition.clear),
        (.windy, .clear),
        (.cloudy, .cloudy),
        (.rainy, .wet),
        (.snowy, .wet),
        (.stormy, .heavy),
        (.foggy, .heavy),
    ])
    func weatherMapsToHowTheLightLooks(weather: WeatherCondition, condition: Sky.Condition) {
        #expect(sky(hour: 12, weather: weather).condition == condition)
    }

    @Test(arguments: [
        (6, Sky.Phase.dawn),
        (12, .day),
        (18, .goldenHour),
        (20, .dusk),
        (23, .night),
        (3, .night),
    ])
    func theClockGivesThePhaseWhenNothingElseIsKnown(hour: Int, phase: Sky.Phase) {
        #expect(sky(hour: hour).phase == phase)
    }

    @Test func unknownWeatherIsPaintedClearNotGrey() {
        #expect(sky(hour: 12) == Sky(phase: .day, condition: .clear))
    }

    @Test func theSavedPhaseWinsOverTheClock() {
        // 15:00 is "day" by the clock, but a December afternoon in Norway is already golden hour.
        #expect(sky(hour: 15, dayPhase: .goldenHour).phase == .goldenHour)
    }

    @Test(arguments: DayPhase.allCases)
    func everySavedPhaseHasItsOwnSky(dayPhase: DayPhase) {
        #expect(sky(hour: 12, dayPhase: dayPhase).phase?.rawValue == dayPhase.rawValue)
    }

    @Test func dominantSkyIsTheMostFrequentOne() {
        let entries = [
            entry(hour: 23, weather: .clear),
            entry(hour: 10, weather: .rainy),
            entry(hour: 11, weather: .snowy),
        ]

        #expect(Sky.dominant(in: entries, calendar: Self.calendar) == Sky(phase: .day, condition: .wet))
    }

    @Test func aTieGoesToTheMostRecentSky() {
        let entries = [
            entry(hour: 10, weather: .clear),
            entry(hour: 23, weather: .clear),
        ]

        #expect(Sky.dominant(in: entries, calendar: Self.calendar) == Sky(phase: .night, condition: .clear))
    }

    @Test func noEntriesMeansNeutral() {
        #expect(Sky.dominant(in: []) == .unknown)
    }

    private func date(hour: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: hour))!
    }

    private func sky(hour: Int, dayPhase: DayPhase? = nil, weather: WeatherCondition? = nil) -> Sky {
        Sky(at: date(hour: hour), dayPhase: dayPhase, weather: weather, calendar: Self.calendar)
    }

    private func entry(hour: Int, weather: WeatherCondition) -> Entry {
        Entry(tripID: UUID(), text: "", createdAt: date(hour: hour), weather: weather)
    }
}
