import Domain
import Foundation
import Synchronization

final class MockVoiceRecorder: VoiceRecorder {
    private let startError: VoiceRecorderError?
    private let recording: URL?
    private let cancelled = Mutex(false)

    init(startError: VoiceRecorderError? = nil, recording: URL? = URL.temporaryDirectory.appending(path: "recording.m4a")) {
        self.startError = startError
        self.recording = recording
    }

    var wasCancelled: Bool { cancelled.withLock { $0 } }

    func start() async throws {
        if let startError { throw startError }
    }

    func stop() async -> URL? { recording }

    func cancel() async {
        cancelled.withLock { $0 = true }
    }
}
