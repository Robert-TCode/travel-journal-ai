#if DEBUG
import Foundation
import Observation

/// A Debug-only run on the device that writes a report the eval scripts copy back.
@MainActor
protocol EvalRunner: AnyObject, Observable {
    var progress: String { get }
    var isFinished: Bool { get }
    func run() async
}

struct Timeout: Error, CustomStringConvertible {
    let limit: Duration
    var description: String { "timeout after \(limit)" }
}

/// One stuck model call (a tool that never returns, say) would otherwise hold up the whole report.
func withTimeout<Value: Sendable>(
    _ limit: Duration,
    _ operation: @escaping @Sendable () async throws -> Value
) async throws -> Value {
    try await withThrowingTaskGroup(of: Value.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: limit)
            throw Timeout(limit: limit)
        }
        defer { group.cancelAll() }
        return try await group.next()!
    }
}

/// Written when the run ends, successfully or not, so the script waiting for the report never hangs.
func writeReport(_ text: String, in folder: URL) {
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try? text.write(to: folder.appending(path: "report.md"), atomically: true, encoding: .utf8)
}

extension ProcessInfo.ThermalState: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }
}
#endif
