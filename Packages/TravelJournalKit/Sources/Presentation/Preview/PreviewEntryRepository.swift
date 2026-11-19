import Domain

/// Accepts every save after a short delay, so previews show the saving state too.
struct PreviewEntryRepository: EntryRepository {
    func save(_ entry: Entry) async throws {
        try await Task.sleep(for: .milliseconds(500))
    }
}
