import SwiftUI

struct PendingPhotosStrip: View {
    let photos: [PendingPhoto]
    let onRemove: (PendingPhoto) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    thumbnail(of: photo)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                onRemove(photo)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                            .accessibilityLabel("Remove photo")
                        }
                }
            }
        }
    }

    private func thumbnail(of photo: PendingPhoto) -> some View {
        Group {
            if let image = photo.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.15)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
