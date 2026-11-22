import Domain
import Foundation
import Synchronization

final class MockMediaStore: MediaStore {
    private let shouldFail: Bool
    private let stored = Mutex<[Data]>([])

    init(failing shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var storedPhotos: [Data] { stored.withLock { $0 } }

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
}
