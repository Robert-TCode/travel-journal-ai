import PhotosUI
import SwiftUI

/// Camera (when the device has one), library and voice, side by side. Photos come back as their original bytes.
struct CaptureActionButtons: View {
    let onPhoto: (Data) async -> Void
    let onVoice: () -> Void

    @State private var isShowingCamera = false
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        HStack(spacing: 10) {
            if CameraPicker.isAvailable {
                Button {
                    isShowingCamera = true
                } label: {
                    CaptureActionTile(title: "Camera", systemImage: "camera.fill", tint: .orange)
                }
            }
            PhotosPicker(selection: $selection, maxSelectionCount: 4, matching: .images) {
                CaptureActionTile(title: "Photos", systemImage: "photo.on.rectangle.angled", tint: .blue)
            }
            Button(action: onVoice) {
                CaptureActionTile(title: "Voice", systemImage: "mic.fill", tint: .purple)
            }
        }
        .buttonStyle(.plain)
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

private struct CaptureActionTile: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
