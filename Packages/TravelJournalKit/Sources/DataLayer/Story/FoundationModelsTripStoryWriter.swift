import Domain
import Foundation
import FoundationModels
import os

/// Writes the story with the on-device model. Its 8k context holds a few dozen entries; a longer journal gets its notes
/// trimmed until it fits, and the trimming is logged so the eval can show where the on-device model runs out of room.
public final class FoundationModelsTripStoryWriter: TripStoryWriter {
    private let model: SystemLanguageModel
    private let logger = Logger(subsystem: "TravelJournal", category: "story")

    public init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    public var writer: TripStory.Writer { .onDevice }

    public func write(trip: Trip, entries: [Entry]) async throws -> TripStory.Draft {
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let (journal, noteLength) = try await fittingJournal(for: trip, entries: entries)
            let session = LanguageModelSession(model: model, instructions: StoryPrompt.instructions)
            let response = try await session.respond(to: journal, schema: StoryPrompt.schema(entryCount: entries.count))
            let draft = try StoryPrompt.draft(from: response.content, entries: entries)
            logger.info("""
                story: \(entries.count) entries\(noteLength.map { ", notes trimmed to \($0) characters" } ?? "", privacy: .public), \
                \(Int(start.duration(to: clock.now) / .milliseconds(1))) ms, \
                input \(response.usage.input.totalTokenCount) tokens, output \(response.usage.output.totalTokenCount) tokens
                """)
            return draft
        } catch {
            logger.error("story failed: \(String(describing: error), privacy: .public)")
            throw TripStoryError(error)
        }
    }

    /// The full journal when it fits, otherwise shorter and shorter notes. Throws `tooLong` when even short notes don't fit.
    private func fittingJournal(for trip: Trip, entries: [Entry]) async throws -> (String, Int?) {
        // The schema grows by one label per entry, so a long trip's schema takes real room too.
        let fixed = try await model.tokenCount(for: Instructions(StoryPrompt.instructions))
            + model.tokenCount(for: StoryPrompt.schema(entryCount: entries.count))
        let budget = model.contextSize - StoryPrompt.responseReserve - fixed
        for noteLength in [nil, 300, 150, 60] as [Int?] {
            let journal = StoryPrompt.journal(for: trip, entries: entries, noteLength: noteLength)
            if try await model.tokenCount(for: journal) <= budget {
                return (journal, noteLength)
            }
        }
        throw TripStoryError.tooLong
    }

}
