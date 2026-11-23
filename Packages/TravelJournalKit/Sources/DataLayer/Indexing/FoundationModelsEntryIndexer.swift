import CoreGraphics
import Domain
import Foundation
import FoundationModels
import ImageIO
import os
import Vision

/// One fresh session per entry: a shared one would grow its transcript and leak earlier notes into later answers.
public final class FoundationModelsEntryIndexer: EntryIndexer {
    private let model: SystemLanguageModel
    private let media: any MediaStore
    private let logger = Logger(subsystem: "TravelJournal", category: "indexing")

    /// Image tokens grow with resolution; this is plenty to recognize a dish or a landscape.
    private static let maxPhotoPixelSize = 1024

    /// Off until the photo eval shows that reading text pays for its extra call; the model already sees the photo.
    private let readsTextInPhotos: Bool

    public init(model: SystemLanguageModel = .default, media: any MediaStore, readsTextInPhotos: Bool = false) {
        self.model = model
        self.media = media
        self.readsTextInPhotos = readsTextInPhotos
    }

    /// What one indexing call cost. The app only logs it; the photo eval reports it.
    public struct Measurement: Sendable {
        public let milliseconds: Int
        public let inputTokens: Int
        public let outputTokens: Int
        public let toolCalls: Int
    }

    public func index(_ entry: Entry) async throws -> EntryIndex {
        try await measuredIndex(entry).index
    }

    public func measuredIndex(_ entry: Entry) async throws -> (index: EntryIndex, measurement: Measurement) {
        let text = IndexingPrompt.prompt(for: entry)
        // Only the first photo for now: each image costs tokens and latency on a small context.
        let photo = entry.photoNames.first.flatMap { Self.downsampledImage(at: media.photoURL(named: $0)) }
        // The model decides whether a photo has text worth reading; without a photo there is nothing to read.
        let tools = readsTextInPhotos && photo != nil ? Self.textReadingTools : []
        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: IndexingPrompt.instructions(readsTextInPhotos: !tools.isEmpty)
        )
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

        let usage = response.usage
        let measurement = Measurement(
            milliseconds: Int(start.duration(to: clock.now) / .milliseconds(1)),
            inputTokens: usage.input.totalTokenCount,
            outputTokens: usage.output.totalTokenCount,
            toolCalls: session.transcript.filter { if case .toolCalls = $0 { true } else { false } }.count
        )
        logger.info("""
            index \(entry.id, privacy: .public)\(photo == nil ? "" : " with photo", privacy: .public), \
            \(entry.nearbyPlaces.count) nearby places: \(measurement.milliseconds) ms, \
            input \(usage.input.totalTokenCount) tokens (\(usage.input.cachedTokenCount) cached), \
            output \(usage.output.totalTokenCount) tokens, \(measurement.toolCalls) tool calls
            """)

        return (index, measurement)
    }

    /// `OCRTool` doesn't exist in the simulator SDK, so there the option silently does nothing.
    private static var textReadingTools: [any Tool] {
        #if targetEnvironment(simulator)
        []
        #else
        [OCRTool()]
        #endif
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
