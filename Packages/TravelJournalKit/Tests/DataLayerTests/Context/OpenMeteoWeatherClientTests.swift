import Foundation
import Testing
import Domain
@testable import DataLayer

@Suite("Open-Meteo weather mapping")
struct OpenMeteoWeatherClientTests {
    @Test(arguments: [
        (0, WeatherCondition.clear), (1, .clear),
        (2, .cloudy), (3, .cloudy),
        (45, .foggy), (48, .foggy),
        (51, .rainy), (67, .rainy), (80, .rainy), (82, .rainy),
        (71, .snowy), (77, .snowy), (85, .snowy), (86, .snowy),
        (95, .stormy), (99, .stormy),
    ])
    func mapsWeatherCodes(code: Int, expected: WeatherCondition) {
        #expect(OpenMeteoWeatherClient.condition(weatherCode: code, windSpeed: 5) == expected)
    }

    @Test(arguments: [0, 1, 2, 3])
    func strongWindWinsOverAQuietSky(code: Int) {
        #expect(OpenMeteoWeatherClient.condition(weatherCode: code, windSpeed: 45) == .windy)
    }

    @Test func strongWindDoesNotHideRainOrSnow() {
        #expect(OpenMeteoWeatherClient.condition(weatherCode: 61, windSpeed: 60) == .rainy)
        #expect(OpenMeteoWeatherClient.condition(weatherCode: 73, windSpeed: 60) == .snowy)
    }

    @Test func unknownCodeHasNoCondition() {
        #expect(OpenMeteoWeatherClient.condition(weatherCode: 42, windSpeed: 5) == nil)
    }

    /// Shape copied from a real response (Hakone, 23 Nov 2026), so a format change on their side shows up here.
    private static let hakone = """
        {"latitude":35.25,"longitude":139.0,"utc_offset_seconds":32400,"timezone":"Asia/Tokyo",
         "current_units":{"time":"unixtime","weather_code":"wmo code"},
         "current":{"time":1795429800,"interval":900,"weather_code":3,"is_day":0,"wind_speed_10m":6.0},
         "daily_units":{"time":"unixtime","sunrise":"unixtime","sunset":"unixtime"},
         "daily":{"time":[1795359600],"sunrise":[1795382774],"sunset":[1795419245]}}
        """

    @Test func readsARealResponse() {
        let reading = OpenMeteoWeatherClient.reading(from: Data(Self.hakone.utf8), at: Date(timeIntervalSince1970: 1_795_429_800))

        #expect(reading == .init(condition: .cloudy, dayPhase: .night))
    }

    @Test func thePhaseComesFromThatPlacesSunset() {
        let halfHourBeforeSunset = Date(timeIntervalSince1970: 1_795_419_245 - 1800)

        let reading = OpenMeteoWeatherClient.reading(from: Data(Self.hakone.utf8), at: halfHourBeforeSunset)

        #expect(reading?.dayPhase == .goldenHour)
    }

    /// In polar night Open-Meteo returns the same instant for sunrise and sunset (seen for Longyearbyen).
    @Test func withoutARealSunriseItFallsBackToDayOrNight() {
        let json = """
            {"current":{"time":1795429800,"weather_code":0,"is_day":0,"wind_speed_10m":3.0},
             "daily":{"time":[1795388400],"sunrise":[1795388400],"sunset":[1795388400]}}
            """

        let reading = OpenMeteoWeatherClient.reading(from: Data(json.utf8), at: Date(timeIntervalSince1970: 1_795_429_800))

        #expect(reading?.dayPhase == .night)
    }

    @Test func aResponseWithoutDailyDataStillGivesAReading() {
        let json = """
            {"current":{"time":1795429800,"weather_code":0,"is_day":1,"wind_speed_10m":3.0}}
            """

        let reading = OpenMeteoWeatherClient.reading(from: Data(json.utf8), at: .now)

        #expect(reading == .init(condition: .clear, dayPhase: .day))
    }

    @Test func garbageGivesNoReading() {
        #expect(OpenMeteoWeatherClient.reading(from: Data("not json".utf8), at: .now) == nil)
    }
}
