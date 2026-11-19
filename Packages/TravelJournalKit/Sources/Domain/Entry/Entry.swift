import Foundation

/// A memory as the user captured it. `text` is stored verbatim; the model only ever adds metadata next to it.
public struct Entry: Sendable, Equatable, Identifiable {
    public let id: UUID
    public var text: String
    public let createdAt: Date
    public var indexingStatus: IndexingStatus

    public init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = .now,
        indexingStatus: IndexingStatus = .pending
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.indexingStatus = indexingStatus
    }

    /// Where the silent, after-save indexing stands. Persisted, so pending work survives an app restart.
    public enum IndexingStatus: Sendable, Equatable {
        case pending
        case done
        case failed
    }
}
