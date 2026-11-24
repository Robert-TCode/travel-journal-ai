import CoreSpotlight
import Domain
import Foundation
import os
import UniformTypeIdentifiers

/// Entries in the app's Core Spotlight index. The same index feeds the system search and, later,
/// `SpotlightSearchTool`, so what is set here is exactly what both can match.
public struct SpotlightEntryIndex: EntrySearchIndex {
    private let media: any MediaStore
    private let logger = Logger(subsystem: "TravelJournal", category: "search")

    public init(media: any MediaStore) {
        self.media = media
    }

    public func index(_ entries: [SearchableEntry]) async throws {
        guard !entries.isEmpty else { return }
        do {
            try await CSSearchableIndex.default().indexSearchableItems(entries.map(item(for:)))
            logger.info("indexed \(entries.count) entries for search")
        } catch {
            // Callers ignore the failure so saving never depends on search; the log is the only trace of it.
            logger.error("search indexing failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    func item(for searchable: SearchableEntry) -> CSSearchableItem {
        let entry = searchable.entry
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        let words = [entry.text, entry.transcript].compactMap { $0 }.filter { !$0.isEmpty }

        attributes.title = Self.title(for: entry)
        attributes.contentDescription = words.first
        attributes.textContent = words.joined(separator: "\n")
        attributes.keywords = entry.tags + [entry.landmark].compactMap { $0 }
        attributes.containerTitle = searchable.tripName
        attributes.containerIdentifier = entry.tripID.uuidString
        attributes.namedLocation = [entry.landmark, entry.placeName].compactMap { $0 }.joined(separator: ", ")
        attributes.contentCreationDate = entry.createdAt
        if let coordinate = entry.coordinate {
            attributes.latitude = NSNumber(value: coordinate.latitude)
            attributes.longitude = NSNumber(value: coordinate.longitude)
        }
        attributes.thumbnailURL = entry.photoNames.first.map(media.photoURL(named:))

        // The entry's own id, so a search result maps straight back to a stored entry.
        return CSSearchableItem(
            uniqueIdentifier: entry.id.uuidString,
            domainIdentifier: entry.tripID.uuidString,
            attributeSet: attributes
        )
    }

    /// The first line of the note, so a result reads like the memory itself.
    static func title(for entry: Entry) -> String {
        let firstLine = [entry.text, entry.transcript ?? ""]
            .lazy
            .compactMap { $0.split(whereSeparator: \.isNewline).first.map(String.init) }
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let firstLine {
            return firstLine.count > 80 ? String(firstLine.prefix(79)) + "…" : firstLine
        }
        return entry.audioName != nil ? "Voice note" : "Photo"
    }
}
