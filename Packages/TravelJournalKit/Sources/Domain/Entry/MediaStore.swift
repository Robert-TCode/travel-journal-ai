import Foundation

/// Keeps the user's photos inside the app, so a memory never depends on the photo library.
public protocol MediaStore: Sendable {
    /// Stores the photo as given and returns its file name.
    func storePhoto(_ data: Data) async throws -> String

    func photoURL(named name: String) -> URL
}
