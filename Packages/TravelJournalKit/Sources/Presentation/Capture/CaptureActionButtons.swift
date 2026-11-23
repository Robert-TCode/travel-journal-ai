import DesignSystem
import PhotosUI
import SwiftUI

/// Camera (when the device has one), library and voice. Photos come back as their original bytes.
struct CaptureActionButtons: View {
    let onPhoto: (Data) async -> Void
    let onVoice: () -> Void

    @State private var isShowingCamera = false
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        HStack(spacing: Spacing.s) {
            if CameraPicker.isAvailable {
                Button("Camera", systemImage: "camera") { isShowingCamera = true }
            }
            PhotosPicker(selection: $selection, maxSelectionCount: 4, matching: .images) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            Button("Voice note", systemImage: "mic", action: onVoice)
        }
        .buttonStyle(.dsIconAction)
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { data in
                Task { await onPhoto(data) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: selection) { _, items in
            guard !items.isEmpty else { return }
            selection = []
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await onPhoto(data)
                    }
                }
            }
        }
    }
}
