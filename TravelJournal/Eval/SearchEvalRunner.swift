#if DEBUG
import CoreSpotlight
import DataLayer
import Domain
import Foundation
import FoundationModels
import Observation

/// Runs the real search on this phone's own journal for each question in Documents/SearchEval/queries.txt
/// and writes report.md there. On the device because the search tool's model assets aren't in the simulator.
/// The report lists the journal's entries so the answers can be judged: it is personal and stays out of the repo.
@MainActor @Observable
final class SearchEvalRunner: EvalRunner {
    private(set) var progress = "Waiting"
    private(set) var isFinished = false

    static let folder = URL.documentsDirectory.appending(path: "SearchEval")

    private let entries: SearchIndexingEntryRepository
    private let trips: any TripRepository

    init(entries: SearchIndexingEntryRepository, trips: any TripRepository) {
        self.entries = entries
        self.trips = trips
    }

    func run() async {
        try? FileManager.default.removeItem(at: Self.folder.appending(path: "report.md"))
        let queries: [String]
        do {
            queries = try String(contentsOf: Self.folder.appending(path: "queries.txt"), encoding: .utf8)
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        } catch {
            return finish("Couldn't read \(Self.folder.path(percentEncoded: false))/queries.txt: \(error)")
        }

        progress = "Indexing the journal…"
        await entries.reindexAll()
        let stored = await first(of: entries.allEntryUpdates())
        let tripNames = Dictionary(await first(of: trips.tripUpdates()).map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let titles = Dictionary(stored.map { ($0.id, SpotlightEntryIndex.title(for: $0)) }, uniquingKeysWith: { first, _ in first })

        // Add a (name, instructions) pair to compare a candidate prompt against the shipped one.
        let variants: [(name: String, instructions: String?)] = [
            ("Shipped instructions", nil),
        ]
        var sections: [String] = []
        var summaries: [String] = []
        for variant in variants {
            let searcher = FoundationModelsMemorySearcher(retrievalInstructions: variant.instructions)
            var rows: [String] = []
            var milliseconds = 0, answered = 0, found = 0
            for (number, query) in queries.enumerated() {
                progress = "\(variant.name)\n\(number + 1)/\(queries.count): \(query)"
                do {
                    let trace = try await withTimeout(.seconds(90)) { try await searcher.tracedSearch(query) }
                    let chosen = trace.chosen.map { titles[$0] ?? "(not stored) \($0)" }
                    let notChosen = trace.candidates.filter { !trace.chosen.contains($0) }.map { titles[$0] ?? "(not stored)" }
                    milliseconds += trace.retrievalMilliseconds + trace.selectionMilliseconds
                    answered += 1
                    found += chosen.isEmpty ? 0 : 1
                    let searches = trace.toolQueries.map { "`\($0)`" }.joined(separator: "<br>")
                    rows.append("| \(query) | \(searches.isEmpty ? "no search" : searches) | \(chosen.isEmpty ? "— nothing found" : chosen.joined(separator: "<br>")) | \(notChosen.joined(separator: "<br>")) | \(trace.retrievalMilliseconds) | \(trace.selectionMilliseconds) | \(trace.inputTokens)/\(trace.outputTokens) |")
                } catch {
                    rows.append("| \(query) | | ERROR \(error) | | | | |")
                }
            }
            summaries.append("\(variant.name): answered \(answered)/\(queries.count) · found something for \(found) · avg \(milliseconds / max(answered, 1)) ms")
            sections.append("""
                ## \(variant.name)

                | Question | Searches the model ran | Chosen | Retrieved, not chosen | Retrieval ms | Selection ms | tokens in/out |
                |---|---|---|---|---|---|---|
                \(rows.joined(separator: "\n"))
                """)
        }

        let journal = stored.map { entry in
            "| \(titles[entry.id] ?? "") | \(tripNames[entry.tripID] ?? "") | \(entry.tags.joined(separator: ", ")) | \(entry.categories.map(\.rawValue).joined(separator: ", ")) | \(entry.indexingStatus.rawValue) |"
        }
        let report = """
            # Search eval

            \(Date.now.formatted(date: .abbreviated, time: .shortened)), \(stored.count) entries, \(queries.count) questions, thermal \(ProcessInfo.processInfo.thermalState.label)
            \(summaries.map { "- \($0)" }.joined(separator: "\n"))

            \(sections.joined(separator: "\n\n"))

            ## Journal

            | Entry | Trip | Tags | Categories | Indexing |
            |---|---|---|---|---|
            \(journal.joined(separator: "\n"))
            """
        writeReport(report, in: Self.folder)
        progress = "Done.\n" + summaries.joined(separator: "\n")
        isFinished = true
    }

    private func finish(_ message: String) {
        writeReport(message, in: Self.folder)
        progress = message
        isFinished = true
    }

    private func first<Element>(of stream: AsyncStream<[Element]>) async -> [Element] {
        for await elements in stream {
            return elements
        }
        return []
    }
}
#endif
