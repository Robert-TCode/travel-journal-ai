/// Gathered by code, never by the model. Each field is nil when there was no permission, signal or network.
public struct EntryContext: Sendable, Equatable {
    public let coordinate: Coordinate?
    public let placeName: String?
    public let weather: WeatherCondition?
    public let dayPhase: DayPhase?

    public init(
        coordinate: Coordinate? = nil,
        placeName: String? = nil,
        weather: WeatherCondition? = nil,
        dayPhase: DayPhase? = nil
    ) {
        self.coordinate = coordinate
        self.placeName = placeName
        self.weather = weather
        self.dayPhase = dayPhase
    }

    public static let empty = EntryContext()
}
