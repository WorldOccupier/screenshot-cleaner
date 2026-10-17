import CleanerCore
import SwiftUI

/// One screenshot thumbnail on a rounded card.
struct ScreenshotCard: View {
    static let size = CGSize(width: 96, height: 64)
    let url: URL
    @State private var image: CGImage?
    @Environment(\.displayScale) private var scale

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        ZStack(alignment: .top) {
            shape.fill(.background)
            if let image {
                // Fill and anchor to the top: a screenshot's most recognizable part is usually its top edge.
                // Slivers and very tall captures are shown whole instead of as a blurry crop.
                let fit = ThumbnailLayout.shouldFit(width: image.width, height: image.height)
                Image(decorative: image, scale: scale)
                    .resizable()
                    .aspectRatio(contentMode: fit ? .fit : .fill)
                    .padding(fit ? 10 : 0)
                    .frame(width: Self.size.width, height: Self.size.height, alignment: fit ? .center : .top)
                    .transition(.opacity)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 5)
        .task(id: url) {
            let loaded = await ThumbnailLoader.load(url, maxPixels: Self.size.width * 3 * scale)
            withAnimation(.easeOut(duration: 0.4)) { image = loaded }
        }
    }
}
