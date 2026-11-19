/// Coarse weather at the moment an entry was captured. Detail is intentionally low: it's for tags and search, not forecasts.
public enum WeatherCondition: String, Sendable, Equatable, CaseIterable {
    case sunny
    case cloudy
    case rainy
    case snowy
    case windy
    case foggy
    case stormy
}
