import AVFoundation
import Domain

/// AAC in an .m4a file: small enough to keep every voice note, and readable by the transcriber.
@MainActor
public final class AudioFileVoiceRecorder: VoiceRecorder {
    private var recorder: AVAudioRecorder?
    /// Starting waits for permission and the audio session; the sheet can be cancelled or swiped away meanwhile.
    private var isStarting = false
    private var cancelledWhileStarting = false

    public nonisolated init() {}

    public func start() async throws {
        isStarting = true
        cancelledWhileStarting = false
        defer { isStarting = false }
        guard await AVAudioApplication.requestRecordPermission() else {
            throw VoiceRecorderError.microphoneAccessDenied
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .spokenAudio)
        // The synchronous setActive blocks the main thread long enough that the recording sheet seemed not to open.
        _ = try await session.activate(options: [])
        // Without this, a recording cancelled mid-start would begin after its sheet is gone, with the mic left on.
        guard !cancelledWhileStarting, !Task.isCancelled else {
            await Self.deactivateSession()
            throw CancellationError()
        }

        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
    }

    public func stop() async -> URL? {
        guard let recorder else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        await Self.deactivateSession()
        return duration > 0.5 ? recorder.url : nil
    }

    public func cancel() async {
        guard let recorder else {
            if isStarting { cancelledWhileStarting = true }
            return
        }
        recorder.stop()
        recorder.deleteRecording()
        self.recorder = nil
        await Self.deactivateSession()
    }

    /// Lets music or a podcast that was paused for the recording resume.
    private static func deactivateSession() async {
        _ = try? await AVAudioSession.sharedInstance().deactivate(options: .notifyOthersOnDeactivation)
    }
}
