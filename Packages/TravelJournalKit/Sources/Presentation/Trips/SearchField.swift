import DesignSystem
import SwiftUI

struct SearchField: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "sparkle.magnifyingglass")
                .foregroundStyle(Palette.secondaryInk)
            TextField("Ask your memories, e.g. black ice cream", text: $text)
                .font(.dsBody)
                .foregroundStyle(Palette.ink)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondaryInk)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Spacing.m)
        .dsSurface()
    }
}
