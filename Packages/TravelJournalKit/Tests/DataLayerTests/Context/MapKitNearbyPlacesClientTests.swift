import Testing
@testable import DataLayer

@Suite("Nearby places")
struct MapKitNearbyPlacesClientTests {
    @Test func nearestFirstWithoutDuplicatesUpToTheLimit() {
        let places = [
            (name: "Hakone Ropeway", distance: 120.0),
            (name: "Owakudani", distance: 15.0),
            (name: "7-Eleven", distance: 80.0),
            (name: "7-Eleven", distance: 200.0),
            (name: "Kurotamago-kan", distance: 40.0),
        ]

        let names = MapKitNearbyPlacesClient.nearestNames(places, maximumCount: 3)

        #expect(names == ["Owakudani", "Kurotamago-kan", "7-Eleven"])
    }

    @Test func leavesOutBlankNamesAndOnesThatLookLikeNoLandmark() {
        let places = [(name: " ", distance: 1.0), (name: "None", distance: 2.0), (name: "Owakudani", distance: 3.0)]

        #expect(MapKitNearbyPlacesClient.nearestNames(places, maximumCount: 8) == ["Owakudani"])
    }
}
