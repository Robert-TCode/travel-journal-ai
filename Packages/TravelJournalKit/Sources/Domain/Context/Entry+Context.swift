extension Entry {
    /// Only fills what is missing, never overwrites.
    public func applying(_ context: EntryContext) -> Entry {
        var updated = self
        updated.coordinate = coordinate ?? context.coordinate
        updated.placeName = placeName ?? context.placeName
        updated.weather = weather ?? context.weather
        updated.dayPhase = dayPhase ?? context.dayPhase
        if nearbyPlaces.isEmpty {
            updated.nearbyPlaces = context.nearbyPlaces
        }
        return updated
    }
}
