import CoreGraphics
import Domain
import Foundation
import FoundationModels
import ImageIO
import os

/// One fresh session per entry: a shared one would grow its transcript and leak earlier notes into later answers.
public final class FoundationModelsEntryIndexer: EntryIndexer {
    private let model: SystemLanguageModel
    private let media: any MediaStore
    private let logger = Logger(subsystem: "TravelJournal", category: "indexing")

    /// Image tokens grow with resolution; this is plenty to recognize a dish or a landscape.
    private static let maxPhotoPixelSize = 1024

    public init(model: SystemLanguageModel = .default, media: any MediaStore) {
        self.model = model
        self.media = media
    }

    public func index(_ entry: Entry) async throws -> EntryIndex {
        let session = LanguageModelSession(model: model, instructions: IndexingPrompt.instructions)
        let text = IndexingPrompt.prompt(for: entry)
        // Only the first photo for now: each image costs tokens and latency on a small context.
        let photo = entry.photoNames.first.flatMap { Self.downsampledImage(at: media.photoURL(named: $0)) }
        let clock = ContinuousClock()
        let start = clock.now

        let response: LanguageModelSession.Response<GeneratedContent>
        let index: EntryIndex
        do {
            let schema = try IndexingSchema.schema(nearbyPlaces: entry.nearbyPlaces)
            response = try await session.respond(schema: schema) {
                text
                if let photo {
                    Attachment(photo).label("photo")
                }
            }
            index = try IndexingSchema.index(from: response.content)
        } catch {
            logger.error("index \(entry.id, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw IndexingError(error)
        }

        let elapsed = start.duration(to: clock.now)
        let usage = response.usage
        logger.info("""
            index \(entry.id, privacy: .public)\(photo == nil ? "" : " with photo", privacy: .public), \
            \(entry.nearbyPlaces.count) nearby places: \
            \(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000) ms, \
            input \(usage.input.totalTokenCount) tokens (\(usage.input.cachedTokenCount) cached), \
            output \(usage.output.totalTokenCount) tokens
            """)

        return index
    }

    private static func downsampledImage(at url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPhotoPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
