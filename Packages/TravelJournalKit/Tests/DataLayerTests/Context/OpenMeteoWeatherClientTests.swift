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

    /// Shape copied from a real response, so a format change on their side shows up here.
    @Test func readsARealResponse() {
        let json = """
            {"latitude":35.25,"longitude":139.0,"current_units":{"weather_code":"wmo code"},
             "current":{"time":"2026-11-22T18:15","interval":900,"weather_code":3,"is_day":0,"wind_speed_10m":6.0}}
            """

        let reading = OpenMeteoWeatherClient.reading(from: Data(json.utf8))

        #expect(reading == .init(condition: .cloudy, isDaytime: false))
    }

    @Test func garbageGivesNoReading() {
        #expect(OpenMeteoWeatherClient.reading(from: Data("not json".utf8)) == nil)
    }
}
