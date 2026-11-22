import Foundation
import Testing
import UIKit
@testable import DataLayer

@Suite("FileMediaStore")
struct FileMediaStoreTests {
    private let directory = URL.temporaryDirectory.appending(path: "FileMediaStoreTests-\(UUID().uuidString)")
    private var audioDirectory: URL { directory.appending(path: "Audio") }

    @Test func keepsTheOriginalBytes() async throws {
        let sut = FileMediaStore(directory: directory, audioDirectory: audioDirectory)
        let data = try #require(UIImage(systemName: "star")?.pngData())

        let name = try await sut.storePhoto(data)

        #expect(try Data(contentsOf: sut.photoURL(named: name)) == data)
    }

    @Test func namesFilesAfterTheirImageType() async throws {
        let sut = FileMediaStore(directory: directory, audioDirectory: audioDirectory)
        let png = try #require(UIImage(systemName: "star")?.pngData())
        let jpeg = try #require(UIImage(systemName: "star")?.jpegData(compressionQuality: 0.8))

        #expect(try await sut.storePhoto(png).hasSuffix(".png"))
        #expect(try await sut.storePhoto(jpeg).hasSuffix(".jpeg"))
    }

    @Test func everyPhotoGetsItsOwnFile() async throws {
        let sut = FileMediaStore(directory: directory, audioDirectory: audioDirectory)
        let data = try #require(UIImage(systemName: "star")?.pngData())

        let first = try await sut.storePhoto(data)
        let second = try await sut.storePhoto(data)

        #expect(first != second)
    }

    @Test func movesARecordingIntoTheStore() async throws {
        let sut = FileMediaStore(directory: directory, audioDirectory: audioDirectory)
        let recording = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).m4a")
        try Data("audio".utf8).write(to: recording)

        let name = try await sut.storeAudio(movingFrom: recording)

        #expect(name.hasSuffix(".m4a"))
        #expect(try Data(contentsOf: sut.audioURL(named: name)) == Data("audio".utf8))
        #expect(!FileManager.default.fileExists(atPath: recording.path()))
    }
}
