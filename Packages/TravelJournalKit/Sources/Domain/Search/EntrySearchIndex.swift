import Foundation

/// An entry as search sees it: the trip's name travels with it, so "my Japan trip" can match.
public struct SearchableEntry: Sendable, Equatable {
    public let entry: Entry
    public let tripName: String?

    public init(entry: Entry, tripName: String?) {
        self.entry = entry
        self.tripName = tripName
    }
}

/// Makes entries findable. Indexing the same entry again replaces it, so callers never need to check first.
public protocol EntrySearchIndex: Sendable {
    func index(_ entries: [SearchableEntry]) async throws
}
