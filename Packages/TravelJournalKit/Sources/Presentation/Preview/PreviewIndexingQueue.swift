import Domain

/// Ignores everything: previews never run the model.
struct PreviewIndexingQueue: IndexingQueue {
    func enqueue(_ entry: Entry) async {}
}
