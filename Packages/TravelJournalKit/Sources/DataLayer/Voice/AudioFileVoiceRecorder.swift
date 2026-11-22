import AVFoundation
import Domain

/// AAC in an .m4a file: small enough to keep every voice note, and readable by the transcriber.
@MainActor
public final class AudioFileVoiceRecorder: VoiceRecorder {
    private var recorder: AVAudioRecorder?

    public nonisolated init() {}

    public func start() async throws {
        guard await AVAudioApplication.requestRecordPermission() else {
            throw VoiceRecorderError.microphoneAccessDenied
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .spokenAudio)
        try session.setActive(true)

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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return duration > 0.5 ? recorder.url : nil
    }

    public func cancel() async {
        guard let recorder else { return }
        recorder.stop()
        recorder.deleteRecording()
        self.recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
