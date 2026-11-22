/// Callers hand off and move on; they never wait for the model.
public protocol IndexingQueue: Sendable {
    func enqueue(_ entry: Entry) async
}
