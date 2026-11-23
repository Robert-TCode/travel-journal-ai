import Foundation
import Testing
import Domain

@Suite("DayPhase")
struct DayPhaseTests {
    private static let sunrise = Date(timeIntervalSince1970: 1_000_000)
    private static let sunset = sunrise.addingTimeInterval(8 * 3600)

    /// Sunset is 480 minutes after sunrise.
    @Test(arguments: [
        (-41, DayPhase.night),
        (-40, .dawn),
        (19, .dawn),
        (20, .day),
        (419, .day),
        (420, .goldenHour),
        (479, .goldenHour),
        (480, .dusk),
        (519, .dusk),
        (520, .night),
    ] as [(Int, DayPhase)])
    func bandsAroundSunriseAndSunset(minutesAfterSunrise: Int, expected: DayPhase) {
        let date = Self.sunrise.addingTimeInterval(TimeInterval(minutesAfterSunrise * 60))

        #expect(DayPhase(at: date, sunrise: Self.sunrise, sunset: Self.sunset) == expected)
    }
}
