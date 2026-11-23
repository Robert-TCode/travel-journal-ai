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

    func run() async {
        try? FileManager.default.removeItem(at: Self.folder.appending(path: "report.md"))
        let indexer = FoundationModelsEntryIndexer(media: FolderMediaStore(folder: Self.folder))
        let cases: [EvalCase]
        do {
            cases = try JSONDecoder().decode([EvalCase].self, from: Data(contentsOf: Self.folder.appending(path: "cases.json")))
        } catch {
            finish("Couldn't read \(Self.folder.path())/cases.json: \(error)")
            return
        }

        var rows: [String] = []
        var tagHits = 0, moodHits = 0, clean = 0, failures = 0, milliseconds = 0, inputTokens = 0
        for (number, evalCase) in cases.enumerated() {
            progress = "\(number + 1)/\(cases.count): \(evalCase.photo)"
            let entry = Entry(tripID: UUID(), text: evalCase.note ?? "", photoNames: [evalCase.photo])
            do {
                let (index, measurement) = try await indexer.measuredIndex(entry)
                let tags = index.tags.map { $0.lowercased() }
                let hit = tags.contains { tag in evalCase.expect.contains { tag.contains($0) } }
                let forbidden = tags.filter { tag in (evalCase.forbid ?? []).contains { tag.contains($0) } }
                let moodRight = index.mood?.rawValue == evalCase.mood
                tagHits += hit ? 1 : 0
                moodHits += moodRight ? 1 : 0
                clean += forbidden.isEmpty ? 1 : 0
                milliseconds += measurement.milliseconds
                inputTokens += measurement.inputTokens
                rows.append("| \(evalCase.photo) | \(hit ? "✓" : "✗") \(tags.joined(separator: ", ")) | \(moodRight ? "✓" : "✗") \(index.mood?.rawValue ?? "—") | \(forbidden.isEmpty ? "" : forbidden.joined(separator: ", ")) | \(measurement.milliseconds) | \(measurement.inputTokens)/\(measurement.outputTokens) |")
            } catch {
                failures += 1
                rows.append("| \(evalCase.photo) | ERROR \(error) | | | | |")
            }
        }

        let answered = max(cases.count - failures, 1)
        let report = """
            # Photo eval

            \(Date.now.formatted(date: .abbreviated, time: .shortened)), \(cases.count) photos, \(failures) errors

            Expected tag found: \(tagHits)/\(cases.count) · mood right: \(moodHits)/\(cases.count) · no forbidden tags: \(clean)/\(cases.count) \
            · avg \(milliseconds / answered) ms · avg \(inputTokens / answered) input tokens

            | Photo | Tags | Mood | Forbidden | ms | tokens in/out |
            |---|---|---|---|---|---|
            \(rows.joined(separator: "\n"))
            """
        try? report.write(to: Self.folder.appending(path: "report.md"), atomically: true, encoding: .utf8)
        print(report)
        finish("Done: \(tagHits)/\(cases.count) tags, \(moodHits)/\(cases.count) moods. Report in Documents/PhotoEval/report.md")
    }

    /// Also written on failure, so the script waiting for report.md never hangs.
    private func finish(_ message: String) {
        if !FileManager.default.fileExists(atPath: Self.folder.appending(path: "report.md").path()) {
            try? message.write(to: Self.folder.appending(path: "report.md"), atomically: true, encoding: .utf8)
        }
        progress = message
        isFinished = true
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
