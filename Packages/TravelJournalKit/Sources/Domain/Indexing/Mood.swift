/// The fixed mood vocabulary. The model picks from it (or picks nothing); the raw value is what gets stored as a tag.
public enum Mood: String, Sendable, Equatable, CaseIterable {
    case happy
    case excited
    case relaxed
    case amazed
    case tired
    case frustrated
    case nostalgic
}
