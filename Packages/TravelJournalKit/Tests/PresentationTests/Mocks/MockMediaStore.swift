import Domain
import Foundation
import Synchronization

final class MockMediaStore: MediaStore {
    private let shouldFail: Bool
    private let stored = Mutex<[Data]>([])
    private let deleted = Mutex<[String]>([])

    init(failing shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var storedPhotos: [Data] { stored.withLock { $0 } }
    var deletedPhotos: [String] { deleted.withLock { $0 } }

    func storePhoto(_ data: Data) async throws -> String {
        if shouldFail { throw MockRepositoryError() }
        return stored.withLock { photos in
            photos.append(data)
            return "photo-\(photos.count).jpg"
        }
    }

    func photoURL(named name: String) -> URL {
        URL.temporaryDirectory.appending(path: name)
    }

    func deletePhoto(named name: String) async {
        deleted.withLock { $0.append(name) }
    }

    func storeAudio(movingFrom url: URL) async throws -> String {
        if shouldFail { throw MockRepositoryError() }
        return "voice.m4a"
    }

    func audioURL(named name: String) -> URL {
        URL.temporaryDirectory.appending(path: name)
    }
}
