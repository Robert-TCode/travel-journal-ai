import Foundation

public enum VoiceRecorderError: Error, Equatable {
    case microphoneAccessDenied
}

/// Records one voice note at a time into a temporary file.
public protocol VoiceRecorder: Sendable {
    func start() async throws
    /// Stops and returns the recording, or nil when nothing was recorded.
    func stop() async -> URL?
    func cancel() async
}
