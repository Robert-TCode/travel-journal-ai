/// What kind of memory an entry is, from a fixed vocabulary. Used only for search: the Spotlight tool matches words
/// literally and the on-device model doesn't think of synonyms, so "what did I drink" can only find a juice
/// if the juice entry carries the word "drink". Not shown on cards, where tags stay specific.
///
/// Each raw value is the word a traveller would search for: singular, everyday, one word, because the model is told
/// to search single singular words. The list covers what a trip holds from several sides (what was eaten, where it was,
/// what was seen, who was there, what was done, how they got there) and stays short enough that every case is
/// distinct: the whole list is part of the schema, so each case costs tokens on every indexing call.
/// Weather and time of day are not here: they come from the device and are indexed as words directly.
public enum EntryCategory: String, Sendable, Equatable, CaseIterable {
    // Eating and drinking
    case food
    case drink
    case coffee
    case dessert
    case market

    // Nature
    case nature
    case beach
    case mountain
    case water
    case forest
    case garden
    case animal
    case plant

    // Places and culture
    case city
    case street
    case architecture
    case landmark
    case religion
    case museum
    case art
    case history
    case view

    // People
    case people
    case friend
    case family

    // Doing things
    case hike
    case sport
    case nightlife
    case music
    case festival
    case shopping
    case relaxation

    // Getting around and staying
    case transport
    case flight
    case train
    case car
    case boat
    case hotel
}
