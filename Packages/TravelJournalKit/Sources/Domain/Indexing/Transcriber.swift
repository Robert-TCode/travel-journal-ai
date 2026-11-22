/// Turns a stored voice note into text, on device.
public protocol Transcriber: Sendable {
    func transcribe(audioNamed name: String) async throws -> String
}
