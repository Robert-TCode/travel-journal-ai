/// Never throws: missing data is simply nil, and the entry is saved anyway.
public protocol EntryContextProvider: Sendable {
    func currentContext() async -> EntryContext
}
