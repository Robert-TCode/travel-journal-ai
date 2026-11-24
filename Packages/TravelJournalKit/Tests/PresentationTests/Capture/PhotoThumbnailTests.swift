import Foundation
import Testing
import UIKit
@testable import Presentation

@Suite("Photo thumbnail")
struct PhotoThumbnailTests {
    /// Photos are stored under "Application Support"; a percent-encoded path ("Application%20Support")
    /// points at no file, and every thumbnail stayed empty.
    @Test func loadsAPhotoFromAFolderWithASpaceInItsName() async throws {
        let folder = URL.temporaryDirectory.appending(path: "Application Support \(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "photo.png")
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        try #require(photo.pngData()).write(to: url)

        let thumbnail = await PhotoThumbnail.thumbnail(of: url, side: 20)

        #expect(thumbnail != nil)
    }
}
