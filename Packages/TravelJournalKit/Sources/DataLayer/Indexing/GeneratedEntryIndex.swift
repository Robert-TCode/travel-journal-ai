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

    /// Not optional: in the eval the model almost never generated a missing value, but it does pick `none` when offered.
    @Guide(description: "The writer's feeling, only if the note states or clearly shows one. Most notes are plain facts like schedules, directions or lists: use none.")
    var mood: GeneratedMood
}

/// Mirrors `Domain.Mood` plus `none`; Domain can't be `@Generable` because it must not import FoundationModels.
@Generable
enum GeneratedMood: CaseIterable {
    case none
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
        EntryIndex(tags: tags, mood: mood.domainValue)
    }
}

extension GeneratedMood {
    var domainValue: Mood? {
        switch self {
        case .none: nil
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
