import Domain
import FoundationModels
import os

/// One fresh session per entry: a shared one would grow its transcript and leak earlier notes into later answers.
public final class FoundationModelsEntryIndexer: EntryIndexer {
    private let model: SystemLanguageModel
    private let logger = Logger(subsystem: "TravelJournal", category: "indexing")

    public init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    public func index(_ entry: Entry) async throws -> EntryIndex {
        let session = LanguageModelSession(model: model, instructions: IndexingPrompt.instructions)
        let clock = ContinuousClock()
        let start = clock.now

        let response = try await session.respond(
            to: IndexingPrompt.prompt(for: entry),
            generating: GeneratedEntryIndex.self
        )

        let elapsed = start.duration(to: clock.now)
        let usage = response.usage
        logger.info("""
            index \(entry.id, privacy: .public): \
            \(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000) ms, \
            input \(usage.input.totalTokenCount) tokens (\(usage.input.cachedTokenCount) cached), \
            output \(usage.output.totalTokenCount) tokens
            """)

        return response.content.domainValue
    }
}
