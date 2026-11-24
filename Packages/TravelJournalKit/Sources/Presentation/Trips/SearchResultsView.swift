import DesignSystem
import Domain
import Foundation
import SwiftUI

struct SearchResultsView: View {
    let state: TripsViewModel.SearchState
    let photoURL: (Entry) -> URL?

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .searching:
            HStack(spacing: Spacing.s) {
                ProgressView()
                Text("Searching your memories on this iPhone…")
                    .font(.dsMeta)
                    .foregroundStyle(Palette.secondaryInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xl)
        case .results(let results) where results.isEmpty:
            message("Nothing in your journal matches that.", detail: "Try other words, a place or a trip name.")
        case .results(let results):
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(results) { result in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        if let tripName = result.tripName {
                            Text(tripName.uppercased())
                                .font(.dsMeta)
                                .foregroundStyle(Palette.secondaryInk)
                        }
                        RecentEntryRow(entry: result.entry, photoURL: photoURL(result.entry))
                    }
                }
            }
        case .failed:
            message("Search isn't available right now.", detail: "Apple Intelligence may be off or still getting ready.")
        }
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.dsTitle)
                .foregroundStyle(Palette.ink)
            Text(detail)
                .font(.dsMeta)
                .foregroundStyle(Palette.secondaryInk)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }
}
