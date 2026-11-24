import CoreSpotlight
import Foundation
import FoundationModels

/// One entry the search tool returned, reduced to what the selection step shows the model.
/// Built from the Spotlight item, so it reflects exactly what was indexed.
struct SearchCandidate: Sendable, Equatable {
    let id: UUID
    let title: String
    let tripName: String?
    let place: String?
    let keywords: [String]
    let date: Date?

    init(id: UUID, title: String, tripName: String? = nil, place: String? = nil, keywords: [String] = [], date: Date? = nil) {
        self.id = id
        self.title = title
        self.tripName = tripName
        self.place = place
        self.keywords = keywords
        self.date = date
    }

    /// Nil for items that aren't journal entries.
    init?(_ item: CSSearchableItem) {
        guard let id = UUID(uuidString: item.uniqueIdentifier) else { return nil }
        let attributes = item.attributeSet
        self.init(
            id: id,
            title: attributes.title ?? "",
            tripName: attributes.containerTitle,
            place: attributes.namedLocation.flatMap { $0.isEmpty ? nil : $0 },
            keywords: attributes.keywords ?? [],
            date: attributes.contentCreationDate
        )
    }
}

/// Search runs in two steps, each with its own session:
/// 1. retrieval: the model turns the question into Spotlight queries through `SpotlightSearchTool`;
/// 2. selection: the model picks the entries that answer the question, from a schema that lists only what step 1 found.
/// IDs never come from the model's free text: step 1 reads them from the tool's results, step 2 can only choose among them.
enum SearchPrompt {
    static let maximumCandidates = 20
    static let maximumAnswers = 6

    /// What the tool hands back for each item: enough to judge relevance, nothing more, to keep the 8k context free.
    static let fetchAttributes: [SearchableItemAttribute] = [
        .title, .keywords, .namedLocation, .containerTitle, .contentCreationDate,
    ]

    /// The tool matches whole words literally ("views" misses "view", "rainy day" misses "rain"), and the model
    /// copies words from the question unless told otherwise. Even told, it rarely tries other words for the same thing.
    static let retrievalInstructions = """
        You find entries in the user's travel journal with the search tool. The tool matches whole words literally, \
        so search one word at a time, in its singular form. Search the words of the question, then related everyday \
        words for the same thing: for "drink" also juice, coffee, beer, tea; for "view" also sunset, mountain, sea. \
        When you are done, answer in one short sentence.
        """

    static let selectionInstructions = """
        You choose which travel journal entries answer the user's question. Use only the entries listed. \
        Pick an entry only when it clearly answers the question, best first. \
        Sharing a word with the question is not enough. If no entry answers it, return an empty list.
        """

    static let answerDescription = "Labels of the entries that answer the question, best first. Empty when none does."

    /// Short labels instead of UUIDs: 36 characters of noise per entry would cost tokens and invite copying mistakes.
    static func label(at index: Int) -> String { "e\(index + 1)" }

    static func selectionPrompt(question: String, candidates: [SearchCandidate], calendar: Calendar = .current) -> String {
        let lines = candidates.enumerated().map { index, candidate in
            var parts = [candidate.title]
            if let tripName = candidate.tripName { parts.append("trip: \(tripName)") }
            if let place = candidate.place { parts.append("place: \(place)") }
            if !candidate.keywords.isEmpty { parts.append("tags: \(candidate.keywords.joined(separator: ", "))") }
            if let date = candidate.date { parts.append(date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "en_US")))) }
            return "\(label(at: index)): \(parts.joined(separator: " | "))"
        }
        return "Question: \(question)\n\nEntries:\n\(lines.joined(separator: "\n"))"
    }

    static func selectionSchema(candidateCount: Int) throws -> GenerationSchema {
        let labels = (0..<candidateCount).map(label(at:))
        let root = DynamicGenerationSchema(name: "Answer", properties: [
            .init(
                name: "entries",
                description: answerDescription,
                schema: DynamicGenerationSchema(arrayOf: DynamicGenerationSchema(name: "EntryLabel", anyOf: labels), maximumElements: maximumAnswers)
            ),
        ])
        return try GenerationSchema(root: root, dependencies: [])
    }

    /// Maps chosen labels back to entry IDs, keeping the model's order and dropping repeats.
    static func ids(from content: GeneratedContent, candidates: [SearchCandidate]) throws -> [UUID] {
        let labels = try content.value([String].self, forProperty: "entries")
        var seen = Set<UUID>()
        return labels.compactMap { label in
            guard let number = Int(label.dropFirst()), candidates.indices.contains(number - 1) else { return nil }
            let id = candidates[number - 1].id
            return seen.insert(id).inserted ? id : nil
        }
    }

    /// Keeps the first occurrence of each entry: the model often runs several queries that overlap.
    static func deduplicated(_ candidates: [SearchCandidate]) -> [SearchCandidate] {
        var seen = Set<UUID>()
        return Array(candidates.filter { seen.insert($0.id).inserted }.prefix(maximumCandidates))
    }
}
