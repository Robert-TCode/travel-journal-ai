import Domain
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct FileMediaStore: MediaStore {
    private let directory: URL
    private let audioDirectory: URL

    public init(
        directory: URL = URL.applicationSupportDirectory.appending(path: "Photos", directoryHint: .isDirectory),
        audioDirectory: URL = URL.applicationSupportDirectory.appending(path: "Audio", directoryHint: .isDirectory)
    ) {
        self.directory = directory
        self.audioDirectory = audioDirectory
    }

    public func storeAudio(movingFrom url: URL) async throws -> String {
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        let name = "\(UUID().uuidString).\(url.pathExtension.isEmpty ? "m4a" : url.pathExtension)"
        try FileManager.default.moveItem(at: url, to: audioURL(named: name))
        return name
    }

    public func audioURL(named name: String) -> URL {
        audioDirectory.appending(path: name, directoryHint: .notDirectory)
    }

    public func storePhoto(_ data: Data) async throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "\(UUID().uuidString).\(Self.fileExtension(for: data))"
        try data.write(to: photoURL(named: name), options: .atomic)
        return name
    }

    public func photoURL(named name: String) -> URL {
        directory.appending(path: name, directoryHint: .notDirectory)
    }

    public func deletePhoto(named name: String) async {
        try? FileManager.default.removeItem(at: photoURL(named: name))
    }

    /// Keeps the original bytes (HEIC stays HEIC); the extension only helps tools that look at it.
    private static func fileExtension(for data: Data) -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source).flatMap({ UTType($0 as String) }),
              let fileExtension = type.preferredFilenameExtension
        else { return "jpg" }
        return fileExtension
    }
}
