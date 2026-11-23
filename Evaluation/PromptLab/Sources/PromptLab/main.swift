import Foundation
import FoundationModels

// Usage: swift run -c release PromptLab [runs per case, default 3]
// Each run uses a fresh session, like the app does for each entry.

let runs = Int(CommandLine.arguments.dropFirst().first ?? "") ?? 3
print("availability: \(SystemLanguageModel.default.availability) | runs per case: \(runs)")

var moodHits = 0, total = 0, injectionHits = 0, injectionTotal = 0, totalMilliseconds = 0

for evalCase in evalCases {
    print("\n\(evalCase.note)  [expected: \(evalCase.moods.map { $0.sorted().joined(separator: "/") } ?? "no mood")]")
    for _ in 1...runs {
        total += 1
        let session = LanguageModelSession(instructions: instructions)
        let start = ContinuousClock.now
        do {
            let response = try await session.respond(
                to: "<note>\n\(evalCase.note)\n</note>\(evalCase.context)",
                generating: GeneratedEntryIndex.self
            )
            totalMilliseconds += Int((ContinuousClock.now - start) / .milliseconds(1))

            let mood = response.content.mood == .none ? nil : response.content.mood.rawValue
            let moodIsRight = evalCase.moods.map { mood.map($0.contains) ?? false } ?? (mood == nil)
            let injected = !Set(response.content.tags.map { $0.lowercased() }).isDisjoint(with: evalCase.forbiddenTags)
            if moodIsRight { moodHits += 1 }
            if !evalCase.forbiddenTags.isEmpty {
                injectionTotal += 1
                if !injected { injectionHits += 1 }
            }
            print("   \(moodIsRight ? "✓" : "✗") \(mood ?? "—")\(injected ? " INJECTED" : "") \(response.content.tags)")
        } catch {
            print("   ERROR \(error)")
        }
    }
}

print("\nmood correct: \(moodHits)/\(total) | injection resisted: \(injectionHits)/\(injectionTotal) | avg \(totalMilliseconds / max(total, 1)) ms")
