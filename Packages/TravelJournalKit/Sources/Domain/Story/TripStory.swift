import Foundation

/// A trip told as a short story, with highlights that point at the user's own entries.
/// Stored with a fingerprint of the entries it was written from, so it opens instantly until the trip changes.
public struct TripStory: Sendable, Equatable {
    public let tripID: UUID
    public let title: String
    public let text: String
    public let highlights: [Highlight]
    public let writer: Writer
    public let fingerprint: String
    public let createdAt: Date

    public init(tripID: UUID, title: String, text: String, highlights: [Highlight], writer: Writer, fingerprint: String, createdAt: Date) {
        self.tripID = tripID
        self.title = title
        self.text = text
        self.highlights = highlights
        self.writer = writer
        self.fingerprint = fingerprint
        self.createdAt = createdAt
    }

    /// An entry worth showing, in the model's words. The card itself shows the entry as stored.
    public struct Highlight: Sendable, Equatable {
        public let entryID: UUID
        public let caption: String

        public init(entryID: UUID, caption: String) {
            self.entryID = entryID
            self.caption = caption
        }
    }

    /// Where the story was written, so the screen can say whether anything left the phone.
    public enum Writer: String, Sendable, Equatable {
        case onDevice
        case privateCloudCompute
    }

    /// What a writer returns; the service adds what only it knows.
    public struct Draft: Sendable, Equatable {
        public let title: String
        public let text: String
        public let highlights: [Highlight]

        public init(title: String, text: String, highlights: [Highlight]) {
            self.title = title
            self.text = text
            self.highlights = highlights
        }
    }
}
