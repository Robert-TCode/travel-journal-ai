import Foundation
import Testing
@testable import DataLayer

/// Transcribes a real recording on device. Off by default: set AUDIO_FIXTURE to the path of an English .m4a.
@Suite(
    "SpeechTranscriberService (real speech)",
    .enabled(if: ProcessInfo.processInfo.environment["AUDIO_FIXTURE"] != nil)
)
struct SpeechTranscriberIntegrationTests {
    @Test(.timeLimit(.minutes(3)))
    func transcribesARecording() async throws {
        let fixture = URL(filePath: try #require(ProcessInfo.processInfo.environment["AUDIO_FIXTURE"]))
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let media = FileMediaStore(directory: directory, audioDirectory: directory)
        let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).m4a")
        try FileManager.default.copyItem(at: fixture, to: copy)
        let name = try await media.storeAudio(movingFrom: copy)

        let transcript = try await SpeechTranscriberService(media: media).transcribe(audioNamed: name)

        print("TRANSCRIPT>> \(transcript)")
        #expect(transcript.localizedCaseInsensitiveContains("feet"))
    }
}
