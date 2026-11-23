import CoreLocation
import Domain
import MapKit

/// Location from CoreLocation ("when in use"), place name from MapKit reverse geocoding,
/// weather and the sun's phase from Open-Meteo, nearby places from MapKit.
public final class DeviceEntryContextProvider: EntryContextProvider {
    private let locationTimeout: Duration
    private let weatherClient = OpenMeteoWeatherClient()
    private let nearbyPlacesClient = MapKitNearbyPlacesClient()

    public init(locationTimeout: Duration = .seconds(5)) {
        self.locationTimeout = locationTimeout
    }

    public func currentContext() async -> EntryContext {
        guard let location = await currentLocation() else { return .empty }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        async let placeName = placeName(for: location)
        async let weather = weatherClient.currentWeather(at: coordinate)
        async let nearbyPlaces = nearbyPlacesClient.places(around: coordinate)
        let reading = await weather
        return EntryContext(
            coordinate: coordinate,
            placeName: await placeName,
            weather: reading?.condition,
            dayPhase: reading?.dayPhase,
            nearbyPlaces: await nearbyPlaces
        )
    }

    /// A fix can take long indoors; past the timeout the entry is saved without a location.
    private func currentLocation() async -> CLLocation? {
        let timeout = locationTimeout
        return await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask { await Self.firstLocation() }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private static func firstLocation() async -> CLLocation? {
        // The session asks for "when in use" permission the first time and keeps it while we listen.
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location { return location }
                if update.authorizationDenied || update.authorizationDeniedGlobally { return nil }
            }
        } catch {
            return nil
        }
        return nil
    }

    private func placeName(for location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let mapItems = try? await request.mapItems
        return mapItems?.first?.addressRepresentations?.cityWithContext
    }
}
