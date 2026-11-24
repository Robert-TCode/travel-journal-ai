/// Turns a stored voice note into text, on device.
public protocol Transcriber: Sendable {
    /// Throws `IndexingError.temporarilyUnavailable` when trying again later can work (speech assets not downloaded yet);
    /// any other error means this recording can't be transcribed.
    func transcribe(audioNamed name: String) async throws -> String
}
