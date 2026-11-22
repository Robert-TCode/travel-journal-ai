import Foundation
import Testing
import Domain
@testable import DataLayer

/// Calls the real Open-Meteo API. Off by default: run with the RUN_NETWORK_TESTS environment variable set.
@Suite("OpenMeteoWeatherClient (real network)", .enabled(if: ProcessInfo.processInfo.environment["RUN_NETWORK_TESTS"] != nil))
struct OpenMeteoWeatherClientIntegrationTests {
    @Test(.timeLimit(.minutes(1)), arguments: [
        ("Owakudani, Hakone", Coordinate(latitude: 35.2424, longitude: 139.0197)),
        ("Preikestolen, Norway", Coordinate(latitude: 58.9864, longitude: 6.1904)),
        ("Bucharest", Coordinate(latitude: 44.4268, longitude: 26.1025)),
    ])
    func returnsAReading(place: String, coordinate: Coordinate) async {
        let reading = await OpenMeteoWeatherClient().currentWeather(at: coordinate)

        print("WEATHER>> \(place): \(reading.map { "\($0.condition?.rawValue ?? "no condition"), \($0.isDaytime ? "day" : "night")" } ?? "no reading")")
        #expect(reading != nil)
    }
}
