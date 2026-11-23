import Foundation

/// Keeps the user's photos inside the app, so a memory never depends on the photo library.
public protocol MediaStore: Sendable {
    /// Stores the photo as given and returns its file name.
    func storePhoto(_ data: Data) async throws -> String

    func photoURL(named name: String) -> URL

    /// For photos stored for an entry that then failed to save; best effort.
    func deletePhoto(named name: String) async

    /// Moves a finished recording into the store and returns its file name.
    func storeAudio(movingFrom url: URL) async throws -> String

    func audioURL(named name: String) -> URL
}
