import Domain
import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct FileMediaStore: MediaStore {
    private let directory: URL

    public init(directory: URL = URL.applicationSupportDirectory.appending(path: "Photos", directoryHint: .isDirectory)) {
        self.directory = directory
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

    /// Keeps the original bytes (HEIC stays HEIC); the extension only helps tools that look at it.
    private static func fileExtension(for data: Data) -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source).flatMap({ UTType($0 as String) }),
              let fileExtension = type.preferredFilenameExtension
        else { return "jpg" }
        return fileExtension
    }
}
