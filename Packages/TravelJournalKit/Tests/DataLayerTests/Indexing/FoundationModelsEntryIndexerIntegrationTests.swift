import Foundation
import FoundationModels
import Testing
import Domain
@testable import DataLayer

/// Calls the real on-device model, so it's slow and non-deterministic. Off by default:
/// run with the RUN_MODEL_TESTS environment variable set, on a device or Mac with Apple Intelligence.
@Suite(
    "FoundationModelsEntryIndexer (real model)",
    .enabled(if: ProcessInfo.processInfo.environment["RUN_MODEL_TESTS"] != nil),
    .enabled(if: SystemLanguageModel.default.isAvailable)
)
struct FoundationModelsEntryIndexerIntegrationTests {
    @Test(.timeLimit(.minutes(1)), arguments: [
        Entry(tripID: UUID(), text: "Walked 20k steps today, my feet hurt and I can't wait to get to the hotel."),
        Entry(tripID: UUID(), text: "Black ice cream at Owakudani, tastes like vanilla!", placeName: "Owakudani, Hakone", weather: .cloudy, isDaytime: true),
        Entry(tripID: UUID(), text: "Bus leaves at 9 from the main station."),
    ])
    func producesAValidIndex(for entry: Entry) async throws {
        let index = try await FoundationModelsEntryIndexer().index(entry)

        print("INDEX>> \(entry.text) -> tags: \(index.tags), mood: \(index.mood.map(\.rawValue) ?? "none")")
        #expect(!index.tags.isEmpty)
        #expect(index.tags.count <= 5)
    }
}
