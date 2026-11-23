import Domain
import Foundation

/// Keyless weather API. Sends only the coordinates; no account, no identifiers.
struct OpenMeteoWeatherClient: Sendable {
    struct Reading: Equatable {
        let condition: WeatherCondition?
        let dayPhase: DayPhase
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func currentWeather(at coordinate: Coordinate, now: Date = .now) async -> Reading? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "weather_code,is_day,wind_speed_10m"),
            // Today's sunrise and sunset at that place, as Unix seconds so no time zone parsing is needed.
            URLQueryItem(name: "daily", value: "sunrise,sunset"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
        ]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        guard let (data, _) = try? await session.data(for: request) else { return nil }
        return Self.reading(from: data, at: now)
    }

    static func reading(from data: Data, at now: Date) -> Reading? {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        let current = response.current
        return Reading(
            condition: condition(weatherCode: current.weatherCode, windSpeed: current.windSpeed),
            dayPhase: dayPhase(at: now, daily: response.daily, isDay: current.isDay == 1)
        )
    }

    /// Polar day and night have no sunrise or sunset; then `is_day` is all we know.
    private static func dayPhase(at now: Date, daily: Response.Daily?, isDay: Bool) -> DayPhase {
        guard let sunrise = daily?.sunrise.first, let sunset = daily?.sunset.first, sunrise < sunset else {
            return isDay ? .day : .night
        }
        return DayPhase(
            at: now,
            sunrise: Date(timeIntervalSince1970: sunrise),
            sunset: Date(timeIntervalSince1970: sunset)
        )
    }

    /// WMO weather interpretation codes, as documented by Open-Meteo.
    /// Wind only wins when the sky itself is unremarkable.
    static func condition(weatherCode: Int, windSpeed: Double) -> WeatherCondition? {
        switch weatherCode {
        case 0...3 where windSpeed >= 40: .windy
        case 0, 1: .clear
        case 2, 3: .cloudy
        case 45, 48: .foggy
        case 51...67, 80...82: .rainy
        case 71...77, 85, 86: .snowy
        case 95...99: .stormy
        default: nil
        }
    }

    private struct Response: Decodable {
        let current: Current
        let daily: Daily?

        struct Daily: Decodable {
            let sunrise: [TimeInterval]
            let sunset: [TimeInterval]
        }

        struct Current: Decodable {
            let weatherCode: Int
            let isDay: Int
            let windSpeed: Double

            enum CodingKeys: String, CodingKey {
                case weatherCode = "weather_code"
                case isDay = "is_day"
                case windSpeed = "wind_speed_10m"
            }
        }
    }
}
