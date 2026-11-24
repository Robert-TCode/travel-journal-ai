import CoreSpotlight
import Domain
import Foundation
import FoundationModels
import os
import Synchronization

/// Local RAG over the journal: `SpotlightSearchTool` retrieves, the on-device model selects. See `SearchPrompt`.
/// Fresh sessions per search, so one question's results never leak into the next.
public final class FoundationModelsMemorySearcher: MemorySearcher {
    private let model: SystemLanguageModel
    private let retrievalInstructions: String
    private let logger = Logger(subsystem: "TravelJournal", category: "search")

    /// `retrievalInstructions` lets the eval try candidates; the app uses `SearchPrompt.retrievalInstructions`.
    public init(model: SystemLanguageModel = .default, retrievalInstructions: String? = nil) {
        self.model = model
        self.retrievalInstructions = retrievalInstructions ?? SearchPrompt.retrievalInstructions
    }

    /// What one search did, for the eval report. The app only logs it.
    public struct Trace: Sendable {
        /// Everything retrieval found, in the order the tool returned it.
        public let candidates: [UUID]
        public let chosen: [UUID]
        public let retrievalMilliseconds: Int
        public let selectionMilliseconds: Int
        public let inputTokens: Int
        public let outputTokens: Int
        /// The arguments of each search the model ran, as JSON: what it actually looked for.
        public let toolQueries: [String]
    }

    public func search(_ question: String) async throws -> [UUID] {
        try await tracedSearch(question).chosen
    }

    public func tracedSearch(_ question: String) async throws -> Trace {
        let clock = ContinuousClock()
        let start = clock.now
        let (candidates, retrievalUsage, toolQueries) = try await retrieve(question)
        let retrieved = clock.now
        var chosen: [UUID] = []
        var selectionUsage = (input: 0, output: 0)
        // Nothing retrieved means nothing to choose from: "not found" without a second model call.
        if !candidates.isEmpty {
            (chosen, selectionUsage) = try await select(from: candidates, for: question)
        }
        let trace = Trace(
            candidates: candidates.map(\.id),
            chosen: chosen,
            retrievalMilliseconds: Self.milliseconds(start.duration(to: retrieved)),
            selectionMilliseconds: Self.milliseconds(retrieved.duration(to: clock.now)),
            inputTokens: retrievalUsage.input + selectionUsage.input,
            outputTokens: retrievalUsage.output + selectionUsage.output,
            toolQueries: toolQueries
        )
        logger.info("""
            search: \(trace.candidates.count) candidates in \(trace.retrievalMilliseconds) ms, \
            \(trace.chosen.count) chosen in \(trace.selectionMilliseconds) ms, \
            input \(trace.inputTokens) tokens, output \(trace.outputTokens) tokens
            """)
        return trace
    }

    private func retrieve(_ question: String) async throws -> ([SearchCandidate], (input: Int, output: Int), [String]) {
        var source = CoreSpotlightSource(fetchAttributes: SearchPrompt.fetchAttributes)
        source.maximumResultCount = SearchPrompt.maximumCandidates
        // `.focused()` keeps tool output small enough for the on-device context. In the eval, a `.dynamic` guide with
        // similarity matching left the tool out of the prompt entirely: the model never searched.
        let tool = SpotlightSearchTool(configuration: .init(sources: [.coreSpotlight(source)], guide: .focused()))
        let found = FoundCandidates()
        // Started before `respond`, as Apple's sample does: replies arrive while the model is still working.
        let collector = Task {
            for await reply in tool.searchResults {
                found.append(Self.items(in: reply).compactMap { SearchCandidate($0.item) })
            }
        }
        defer { collector.cancel() }

        let session = LanguageModelSession(model: model, tools: [tool], instructions: retrievalInstructions)
        let usage: (input: Int, output: Int)
        do {
            let response = try await session.respond(to: question, options: GenerationOptions(maximumResponseTokens: 60))
            usage = (response.usage.input.totalTokenCount, response.usage.output.totalTokenCount)
        } catch {
            logger.error("search retrieval failed: \(String(describing: error), privacy: .public)")
            throw error
        }
        // The tool has returned before `respond` does; this lets its last reply reach the collector.
        await Task.yield()
        let toolQueries = session.transcript.flatMap { entry -> [String] in
            guard case .toolCalls(let calls) = entry else { return [] }
            return calls.map(\.arguments.jsonString)
        }
        return (SearchPrompt.deduplicated(found.all), usage, toolQueries)
    }

    private func select(from candidates: [SearchCandidate], for question: String) async throws -> ([UUID], (input: Int, output: Int)) {
        let session = LanguageModelSession(model: model, instructions: SearchPrompt.selectionInstructions)
        do {
            let response = try await session.respond(
                to: SearchPrompt.selectionPrompt(question: question, candidates: candidates),
                schema: SearchPrompt.selectionSchema(candidateCount: candidates.count)
            )
            let ids = try SearchPrompt.ids(from: response.content, candidates: candidates)
            return (ids, (response.usage.input.totalTokenCount, response.usage.output.totalTokenCount))
        } catch {
            logger.error("search selection failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private static func items(in reply: SpotlightSearchTool.SearchReply) -> [SearchableItem] {
        switch reply.content {
        case .items(let items): items
        case .scoredItems(let scored): scored.map(\.item)
        case .groupedItems(let groups): groups.values.flatMap { $0 }
        // Counts, tables and statistics answer "how many" questions; they carry no entries to show.
        default: []
        }
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        Int(duration / .milliseconds(1))
    }
}

/// Written by the collector task, read once the model is done.
private final class FoundCandidates: Sendable {
    private let candidates = Mutex<[SearchCandidate]>([])

    func append(_ new: [SearchCandidate]) {
        candidates.withLock { $0.append(contentsOf: new) }
    }

    var all: [SearchCandidate] { candidates.withLock { $0 } }
}
