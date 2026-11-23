import DesignSystem
import SwiftUI

struct NoteEditor: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        TextEditor(text: $text)
            .font(.dsBody)
            .foregroundStyle(Palette.ink)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 96)
            .focused(isFocused)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.dsBody)
                        .foregroundStyle(Palette.secondaryInk)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
    }
}
