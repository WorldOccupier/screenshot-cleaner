import CoreGraphics
import Foundation
import ImageIO

enum ThumbnailLoader {
    /// Decodes a downsampled thumbnail with ImageIO, off the main thread. Only the needed pixels are decoded.
    static func load(_ url: URL, maxPixels: CGFloat) async -> CGImage? {
        await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value
    }
}
