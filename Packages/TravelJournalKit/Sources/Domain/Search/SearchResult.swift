import Foundation

/// A found entry with what a result card needs to say where it belongs.
public struct SearchResult: Sendable, Equatable, Identifiable {
    public let entry: Entry
    public let tripName: String?

    public var id: UUID { entry.id }

    public init(entry: Entry, tripName: String?) {
        self.entry = entry
        self.tripName = tripName
    }

    /// Matches found IDs to stored entries in the searcher's order. An ID with no stored entry is dropped:
    /// the search index can briefly lag behind the store, and a card must never show something that isn't there.
    public static func results(for ids: [UUID], entries: [Entry], trips: [Trip]) -> [SearchResult] {
        let entriesByID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let tripNames = Dictionary(trips.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<UUID>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted, let entry = entriesByID[id] else { return nil }
            return SearchResult(entry: entry, tripName: tripNames[entry.tripID])
        }
    }
}
