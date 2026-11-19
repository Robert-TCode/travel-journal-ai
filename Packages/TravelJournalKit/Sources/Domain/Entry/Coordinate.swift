/// A point on Earth, in degrees. Domain's own type so no layer above DataLayer depends on CoreLocation.
public struct Coordinate: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
