import Domain
import Foundation

/// Keyless weather API. Sends only the coordinates; no account, no identifiers.
struct OpenMeteoWeatherClient: Sendable {
    struct Reading: Equatable {
        let condition: WeatherCondition?
        let isDaytime: Bool
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func currentWeather(at coordinate: Coordinate) async -> Reading? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "weather_code,is_day,wind_speed_10m"),
        ]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        guard let (data, _) = try? await session.data(for: request) else { return nil }
        return Self.reading(from: data)
    }

    static func reading(from data: Data) -> Reading? {
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        let current = response.current
        return Reading(
            condition: condition(weatherCode: current.weatherCode, windSpeed: current.windSpeed),
            isDaytime: current.isDay == 1
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
