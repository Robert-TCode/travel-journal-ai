import Foundation

public struct Trip: Sendable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public let startedAt: Date
    public var endedAt: Date?

    public init(id: UUID = UUID(), name: String, startedAt: Date = .now, endedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var isOngoing: Bool { endedAt == nil }
}
