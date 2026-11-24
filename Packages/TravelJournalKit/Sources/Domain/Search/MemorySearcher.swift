import Foundation

/// Answers a question about the journal with entries, never with free text: the screen shows the user's own
/// memories, so the answer can't contain anything the journal doesn't.
public protocol MemorySearcher: Sendable {
    /// The entries that answer `question`, best first. Empty means nothing in the journal does.
    func search(_ question: String) async throws -> [UUID]
}
