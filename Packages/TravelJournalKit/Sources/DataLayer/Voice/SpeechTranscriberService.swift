import AVFoundation
import Domain
import Speech

/// On-device transcription with SpeechAnalyzer. Content is English, so the locale is fixed.
public struct SpeechTranscriberService: Transcriber {
    private let media: any MediaStore
    private let locale = Locale(identifier: "en-US")

    public init(media: any MediaStore) {
        self.media = media
    }

    /// `SpeechTranscriber` is the newer, better model but isn't supported on every device (nor the simulator);
    /// `DictationTranscriber` covers the rest.
    public func transcribe(audioNamed name: String) async throws -> String {
        let file = try AVAudioFile(forReading: media.audioURL(named: name))
        if SpeechTranscriber.isAvailable {
            let module = SpeechTranscriber(locale: locale, preset: .transcription)
            return try await transcribe(file, with: module, results: module.results.map { String($0.text.characters) })
        } else {
            let module = DictationTranscriber(locale: locale, preset: .longDictation)
            return try await transcribe(file, with: module, results: module.results.map { String($0.text.characters) })
        }
    }

    private func transcribe(
        _ file: AVAudioFile,
        with module: some SpeechModule,
        results: some AsyncSequence<String, any Error> & Sendable
    ) async throws -> String {
        // The language model is a separate download; the first voice note triggers it.
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            try await request.downloadAndInstall()
        }
        // The analyzer only accepts specific PCM formats, not the AAC we record in.
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [module]) else {
            throw TranscriptionError.noCompatibleAudioFormat
        }
        let input = try Self.pcmInput(from: file, in: format)

        // Start collecting before analysis begins, so no result is missed.
        async let text = results.reduce(into: "") { $0 += $1 }
        let analyzer = SpeechAnalyzer(modules: [module])
        if let end = try await analyzer.analyzeSequence(input) {
            try await analyzer.finalizeAndFinish(through: end)
        } else {
            await analyzer.cancelAndFinishNow()
        }
        return try await text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reads the whole note and converts it in one pass; voice notes are short, so this stays small.
    private static func pcmInput(from file: AVAudioFile, in format: AVAudioFormat) throws -> AsyncStream<AnalyzerInput> {
        guard let converter = AVAudioConverter(from: file.processingFormat, to: format),
              let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { throw TranscriptionError.noCompatibleAudioFormat }
        try file.read(into: source)

        let ratio = format.sampleRate / file.processingFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(source.frameLength) * ratio) + 1024
        guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw TranscriptionError.noCompatibleAudioFormat
        }
        var consumed = false
        var conversionError: NSError?
        converter.convert(to: converted, error: &conversionError) { _, status in
            if consumed {
                status.pointee = .endOfStream
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return source
        }
        if let conversionError { throw conversionError }

        return AsyncStream { continuation in
            continuation.yield(AnalyzerInput(buffer: converted))
            continuation.finish()
        }
    }
}

enum TranscriptionError: Error {
    case noCompatibleAudioFormat
}
