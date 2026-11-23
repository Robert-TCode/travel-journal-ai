import Foundation
import Observation

/// What the model is writing right now, for screens that stay open while an entry is indexed.
/// Kept in memory on purpose: a half-generated tag must never reach the store, and the stored entry
/// is written once, when indexing finishes.
@MainActor @Observable
public final class LiveIndexing {
    private var previews: [UUID: Entry] = [:]

    nonisolated public init() {}

    /// The entry as it will look with the tags generated so far, while it is still pending.
    public func preview(of entry: Entry) -> Entry? {
        guard entry.indexingStatus == .pending else { return nil }
        return previews[entry.id]
    }

    func show(_ preview: Entry) {
        previews[preview.id] = preview
    }

    func clear(_ id: UUID) {
        previews[id] = nil
    }
}
