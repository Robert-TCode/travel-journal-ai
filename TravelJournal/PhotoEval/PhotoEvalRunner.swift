#if DEBUG
import DataLayer
import Domain
import Foundation
import Observation

/// Runs the real indexer on the photos in Documents/PhotoEval and writes report.md next to them.
/// Lives in the app because image input needs iOS 27, and the model doesn't run under xctest on the simulator.
@MainActor @Observable
final class PhotoEvalRunner {
    struct EvalCase: Decodable {
        let photo: String
        let note: String?
        /// A tag "hits" when it contains one of these words.
        let expect: [String]
        /// Words no tag may contain: invented facts or text that tried to give orders.
        let forbid: [String]?
        /// nil means no mood is expected.
        let mood: String?
    }

    private(set) var progress = "Waiting"
    private(set) var isFinished = false

    static let folder = URL.documentsDirectory.appending(path: "PhotoEval")

    /// With `-ocr`, every photo runs twice, without and with `OCRTool`, so the two variants share one report.
    func run() async {
        try? FileManager.default.removeItem(at: Self.folder.appending(path: "report.md"))
        let cases: [EvalCase]
        do {
            cases = try JSONDecoder().decode([EvalCase].self, from: Data(contentsOf: Self.folder.appending(path: "cases.json")))
        } catch {
            finish("Couldn't read \(Self.folder.path())/cases.json: \(error)")
            return
        }

        var variants = [(name: "Photo only", readsText: false)]
        if ProcessInfo.processInfo.arguments.contains("-ocr") {
            variants.append((name: "Photo + OCRTool", readsText: true))
        }
        var sections: [String] = []
        var summaries: [String] = []
        for variant in variants {
            let indexer = FoundationModelsEntryIndexer(media: FolderMediaStore(folder: Self.folder), readsTextInPhotos: variant.readsText)
            let result = await evaluate(cases, with: indexer, named: variant.name)
            sections.append(result.section)
            summaries.append("\(variant.name): \(result.summary)")
        }

        let report = """
            # Photo eval

            \(Date.now.formatted(date: .abbreviated, time: .shortened)), \(cases.count) photos

            \(summaries.map { "- \($0)" }.joined(separator: "\n"))

            \(sections.joined(separator: "\n\n"))
            """
        try? report.write(to: Self.folder.appending(path: "report.md"), atomically: true, encoding: .utf8)
        print(report)
        finish("Done.\n" + summaries.joined(separator: "\n"))
    }

    private func evaluate(
        _ cases: [EvalCase],
        with indexer: FoundationModelsEntryIndexer,
        named name: String
    ) async -> (section: String, summary: String) {
        var rows: [String] = []
        var tagHits = 0, moodHits = 0, clean = 0, failures = 0, milliseconds = 0, inputTokens = 0, toolCalls = 0
        var hottest = ProcessInfo.ThermalState.nominal
        for (number, evalCase) in cases.enumerated() {
            // A hot phone throttles the model; without this, slow numbers can't be told apart from a slow model.
            let thermal = ProcessInfo.processInfo.thermalState
            hottest = max(hottest, thermal)
            progress = "\(name)\n\(number + 1)/\(cases.count): \(evalCase.photo)\nthermal: \(thermal.label)"
            let entry = Entry(tripID: UUID(), text: evalCase.note ?? "", photoNames: [evalCase.photo])
            do {
                let (index, measurement) = try await Self.withTimeout(.seconds(60)) {
                    try await indexer.measuredIndex(entry)
                }
                let tags = index.tags.map { $0.lowercased() }
                let hit = tags.contains { tag in evalCase.expect.contains { tag.contains($0) } }
                let forbidden = tags.filter { tag in (evalCase.forbid ?? []).contains { tag.contains($0) } }
                let moodRight = index.mood?.rawValue == evalCase.mood
                tagHits += hit ? 1 : 0
                moodHits += moodRight ? 1 : 0
                clean += forbidden.isEmpty ? 1 : 0
                milliseconds += measurement.milliseconds
                inputTokens += measurement.inputTokens
                toolCalls += measurement.toolCalls
                rows.append("| \(evalCase.photo) | \(hit ? "✓" : "✗") \(tags.joined(separator: ", ")) | \(moodRight ? "✓" : "✗") \(index.mood?.rawValue ?? "—") | \(forbidden.joined(separator: ", ")) | \(measurement.toolCalls) | \(measurement.milliseconds) | \(measurement.inputTokens)/\(measurement.outputTokens) | \(thermal.label) |")
            } catch {
                failures += 1
                rows.append("| \(evalCase.photo) | ERROR \(error) | | | | | | \(thermal.label) |")
            }
        }
        let answered = max(cases.count - failures, 1)
        let summary = "expected tag \(tagHits)/\(cases.count) · mood \(moodHits)/\(cases.count) · no forbidden tags \(clean)/\(cases.count) " +
            "· \(toolCalls) tool calls · avg \(milliseconds / answered) ms · avg \(inputTokens / answered) input tokens · \(failures) errors " +
            "· hottest: \(hottest.label)"
        let section = """
            ## \(name)

            | Photo | Tags | Mood | Forbidden | Tool calls | ms | tokens in/out | Thermal |
            |---|---|---|---|---|---|---|---|
            \(rows.joined(separator: "\n"))
            """
        return (section, summary)
    }

    struct Timeout: Error, CustomStringConvertible {
        var description: String { "timeout after 60 s" }
    }

    /// One stuck model call (a tool that never returns, say) would otherwise hold up the whole report.
    private static func withTimeout<Value: Sendable>(
        _ limit: Duration,
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        try await withThrowingTaskGroup(of: Value.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: limit)
                throw Timeout()
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    /// Also written on failure, so the script waiting for report.md never hangs.
    private func finish(_ message: String) {
        try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: Self.folder.appending(path: "report.md").path()) {
            try? message.write(to: Self.folder.appending(path: "report.md"), atomically: true, encoding: .utf8)
        }
        progress = message
        isFinished = true
    }
}

extension ProcessInfo.ThermalState: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }
}

/// Serves the eval photos by name; the indexer only ever reads.
private struct FolderMediaStore: MediaStore {
    let folder: URL

    func photoURL(named name: String) -> URL { folder.appending(path: name) }
    func audioURL(named name: String) -> URL { folder.appending(path: name) }
    func storePhoto(_ data: Data) async throws -> String { throw CocoaError(.featureUnsupported) }
    func storeAudio(movingFrom url: URL) async throws -> String { throw CocoaError(.featureUnsupported) }
}
#endif
