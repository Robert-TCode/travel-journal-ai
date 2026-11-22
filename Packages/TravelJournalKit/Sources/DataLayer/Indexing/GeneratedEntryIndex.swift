import Domain
import FoundationModels

/// The schema the on-device model fills in when indexing an entry. It is part of the prompt:
/// guide descriptions are instructions, and properties are generated top to bottom.
@Generable
struct GeneratedEntryIndex {
    // Tags first: describing what happened helps the model pick a mood that matches it.
    @Guide(
        description: "Short lowercase tags that help find this memory later: activities, food, drinks, places, things. One or two words each.",
        .maximumCount(5)
    )
    var tags: [String]

    @Guide(description: "The writer's mood, only if the note clearly expresses one. Leave empty otherwise; never guess.")
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
