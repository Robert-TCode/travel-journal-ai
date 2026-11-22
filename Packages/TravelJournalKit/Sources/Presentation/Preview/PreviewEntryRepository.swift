import Domain
import Foundation

struct PreviewEntryRepository: EntryRepository {
    func save(_ entry: Entry) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }

    func entryUpdates(tripID: UUID) -> AsyncStream<[Entry]> {
        AsyncStream { continuation in
            continuation.yield([
                Entry(tripID: tripID, text: "Black ice cream at Owakudani."),
                Entry(tripID: tripID, text: "Walked 20k steps today, my feet hurt.", tags: ["walking", "steps", "tired"], indexingStatus: .done),
            ])
            continuation.finish()
        }
    }

    func pendingEntries() -> [Entry] { [] }
}
