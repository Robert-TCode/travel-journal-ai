import Domain

struct StubContextProvider: EntryContextProvider {
    var context: EntryContext = .empty

    func currentContext() async -> EntryContext {
        context
    }
}
