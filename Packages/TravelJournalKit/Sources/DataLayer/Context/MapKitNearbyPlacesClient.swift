import CoreLocation
import Domain
import MapKit

/// Points of interest around the capture point. Like reverse geocoding, this sends the coordinates to Apple.
struct MapKitNearbyPlacesClient: Sendable {
    /// About a few minutes' walk: wide enough for "the viewpoint up the path", narrow enough to stay relevant.
    private let radius: CLLocationDistance = 300
    /// Every candidate is spelled out in the schema, so each one costs prompt tokens.
    private let maximumCount = 8

    /// Places a memory can be *about*. Without a filter the nearest results are restrooms, shops and
    /// rooms inside a museum, and the model, forced to choose, picks a real but wrong name.
    /// Food and drink places are left out for now: they are the most numerous and the closest, so they
    /// crowd out the sights. The photo experiment decides whether that was right.
    static let categories: [MKPointOfInterestCategory] = [
        .landmark, .nationalMonument, .castle, .fortress, .museum, .planetarium, .aquarium, .zoo,
        .nationalPark, .park, .beach, .scenicView, .hiking, .marina,
        .amusementPark, .stadium, .theater, .musicVenue, .winery, .brewery, .distillery,
    ]

    func places(around coordinate: Coordinate) async -> [String] {
        let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let request = MKLocalPointsOfInterestRequest(center: center.coordinate, radius: radius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: Self.categories)
        guard let response = try? await MKLocalSearch(request: request).start() else { return [] }
        return Self.nearestNames(response.mapItems.compactMap { item in
            item.name.map { (name: $0, distance: item.location.distance(from: center)) }
        }, maximumCount: maximumCount)
    }

    /// Nearest first, without duplicates (chains often appear twice).
    static func nearestNames(_ places: [(name: String, distance: CLLocationDistance)], maximumCount: Int) -> [String] {
        var seen = Set<String>()
        return places
            .sorted { $0.distance < $1.distance }
            .map(\.name)
            .filter { seen.insert($0).inserted }
            .prefix(maximumCount)
            .map { $0 }
    }
}
