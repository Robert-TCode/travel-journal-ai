import DesignSystem
import SwiftUI
import UIKit

/// Decodes a small thumbnail off the main thread instead of the full-resolution photo.
struct PhotoThumbnail: View {
    static let defaultSize: CGFloat = 56

    let url: URL
    var size: CGFloat = defaultSize

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Palette.fill
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Radius.thumbnail, style: .continuous))
        .task(id: url) {
            image = await UIImage(contentsOfFile: url.path())?.byPreparingThumbnail(ofSize: CGSize(width: size * 3, height: size * 3))
        }
    }
}
