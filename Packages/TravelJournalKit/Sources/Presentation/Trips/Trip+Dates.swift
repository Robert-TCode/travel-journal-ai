import Domain
import Foundation

extension Trip {
    /// "Since 23 Nov" while ongoing, "23 Nov – 2 Dec 2026" once ended.
    var dateRangeText: String {
        let start = startedAt.formatted(.dateTime.month(.abbreviated).day())
        guard let endedAt else { return "Since \(start)" }
        return "\(start) – \(endedAt.formatted(.dateTime.month(.abbreviated).day().year()))"
    }
}
