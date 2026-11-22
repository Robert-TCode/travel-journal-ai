import Domain

struct PreviewIndexingQueue: IndexingQueue {
    func enqueue(_ entry: Entry) async {}
}
