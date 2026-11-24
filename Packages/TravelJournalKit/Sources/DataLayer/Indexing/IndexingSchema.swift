import Domain
import FoundationModels

/// The schema the model fills. Built at runtime because the landmark choices are this entry's nearby places:
/// constrained decoding then makes an invented place impossible, the model can only pick from the list or `none`.
/// Descriptions are part of the prompt, and properties are generated top to bottom.
enum IndexingSchema {
    static let noLandmark = "none"

    static let landmarkDescription = "The place from this list that the note or photo is clearly about. none when it isn't clearly about one of them."
    static let tagsDescription = "Specific words from the note or its context that someone would search for later, like 'ramen', 'sunset', 'museum'. Never generic categories such as 'food' or 'activities'. Always in English: translate text you read in the photo. Name the exact dish, model or character only when you are sure; a wrong name is worse than a plain word."
    static let categoriesDescription = "What the note or photo is about, for search later: the kinds of thing it shows or tells, not the time or the mood. Anything someone drinks, like juice, coffee or beer, is drink."
    static let moodDescription = "The writer's feeling, only if the note states or clearly shows one. Most notes are plain facts like schedules, directions or lists: use none."

    /// The landmark comes first, so the tags can build on the place the model just chose.
    /// Categories follow the tags: by then the model has named what it sees, and only has to classify it.
    /// Without nearby places there is nothing to choose from, and the property is left out entirely.
    /// The same goes for mood without a note: a property in the schema is one the model will fill.
    static func schema(nearbyPlaces: [String], asksForMood: Bool = true) throws -> GenerationSchema {
        var properties: [DynamicGenerationSchema.Property] = []
        if !nearbyPlaces.isEmpty {
            properties.append(.init(
                name: "landmark",
                description: landmarkDescription,
                schema: DynamicGenerationSchema(name: "Landmark", anyOf: nearbyPlaces + [noLandmark])
            ))
        }
        properties.append(.init(
            name: "tags",
            description: tagsDescription,
            schema: DynamicGenerationSchema(arrayOf: DynamicGenerationSchema(type: String.self), maximumElements: 5)
        ))
        properties.append(.init(
            name: "categories",
            description: categoriesDescription,
            schema: DynamicGenerationSchema(
                arrayOf: DynamicGenerationSchema(name: "Category", anyOf: EntryCategory.allCases.map(\.rawValue)),
                maximumElements: 4
            )
        ))
        if asksForMood {
            properties.append(.init(name: "mood", description: moodDescription, schema: DynamicGenerationSchema(type: GeneratedMood.self)))
        }
        return try GenerationSchema(root: DynamicGenerationSchema(name: "EntryIndex", properties: properties), dependencies: [])
    }

    static func index(from content: GeneratedContent) throws -> EntryIndex {
        let landmark = try? content.value(String.self, forProperty: "landmark")
        return EntryIndex(
            tags: try content.value([String].self, forProperty: "tags"),
            mood: (try? content.value(GeneratedMood.self, forProperty: "mood"))?.domainValue,
            landmark: landmark == noLandmark ? nil : landmark,
            categories: ((try? content.value([String].self, forProperty: "categories")) ?? []).compactMap(EntryCategory.init(rawValue:))
        )
    }

    /// What a streamed snapshot holds so far. Properties that haven't started yet are simply missing,
    /// and the mood is never read: it arrives last and would only flicker in.
    static func partialIndex(from content: GeneratedContent) -> EntryIndex? {
        let tags = (try? content.value([String].self, forProperty: "tags")) ?? []
        let landmark = (try? content.value(String.self, forProperty: "landmark")).flatMap { $0 == noLandmark ? nil : $0 }
        guard !tags.isEmpty || landmark != nil else { return nil }
        return EntryIndex(tags: tags, mood: nil, landmark: landmark)
    }
}

/// Mirrors `Domain.Mood` plus `none`; Domain can't be `@Generable` because it must not import FoundationModels.
/// In the prompt lab the model almost never left an optional mood empty, but it does pick `none` when offered.
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
