import Domain
import FoundationModels

/// Part of the prompt: guide descriptions are instructions, and properties are generated top to bottom.
@Generable
struct GeneratedEntryIndex {
    @Guide(
        description: "Specific words from the note or its context that someone would search for later, like 'ramen', 'sunset', 'museum'. Never generic categories such as 'food' or 'activities'.",
        .maximumCount(5)
    )
    var tags: [String]

    @Guide(description: "Only if the writer states or clearly shows a feeling. Most notes have no mood: leave it empty for plain facts like schedules, directions or lists.")
    var mood: GeneratedMood?
}

/// Mirrors `Domain.Mood`; Domain can't be `@Generable` because it must not import FoundationModels.
@Generable
enum GeneratedMood: CaseIterable {
    case happy
    case excited
    case relaxed
    case amazed
    case tired
    case frustrated
    case nostalgic
}

extension GeneratedEntryIndex {
    var domainValue: EntryIndex {
        EntryIndex(tags: tags, mood: mood?.domainValue)
    }
}

extension GeneratedMood {
    var domainValue: Mood {
        switch self {
        case .happy: .happy
        case .excited: .excited
        case .relaxed: .relaxed
        case .amazed: .amazed
        case .tired: .tired
        case .frustrated: .frustrated
        case .nostalgic: .nostalgic
        }
    }
}
