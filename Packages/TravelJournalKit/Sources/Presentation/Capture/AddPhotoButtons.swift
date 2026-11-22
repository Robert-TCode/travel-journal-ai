import PhotosUI
import SwiftUI

/// Camera (when the device has one) and library, side by side. Hands back each photo's original bytes.
struct AddPhotoButtons: View {
    let onPhoto: (Data) async -> Void

    @State private var isShowingCamera = false
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        HStack(spacing: 10) {
            if CameraPicker.isAvailable {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .tint(.orange)
            }
            PhotosPicker(selection: $selection, maxSelectionCount: 4, matching: .images) {
                Label("Photos", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .tint(.blue)
        }
        .buttonStyle(.bordered)
        .font(.subheadline)
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
