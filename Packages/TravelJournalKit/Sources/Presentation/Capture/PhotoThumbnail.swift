import SwiftUI
import UIKit

/// Decodes a small thumbnail off the main thread instead of the full-resolution photo.
struct PhotoThumbnail: View {
    let url: URL
    var size: CGFloat = 56

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: url) {
            image = await UIImage(contentsOfFile: url.path())?.byPreparingThumbnail(ofSize: CGSize(width: size * 3, height: size * 3))
        }
    }
}
