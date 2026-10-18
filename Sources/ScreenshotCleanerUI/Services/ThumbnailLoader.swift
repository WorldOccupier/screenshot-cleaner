import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

enum ThumbnailLoader {
    /// Decodes a downsampled thumbnail with ImageIO, off the main thread. Only the needed pixels are decoded.
    static func load(_ url: URL, maxPixels: CGFloat) async -> CGImage? {
        if url.pathExtension.lowercased() == "mov" { return await firstFrame(url, maxPixels: maxPixels) }
        return await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value
    }

    /// Screen recordings: grab the first frame with AVFoundation, since ImageIO can't read video.
    private static func firstFrame(_ url: URL, maxPixels: CGFloat) async -> CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixels, height: maxPixels)
        return try? await generator.image(at: .zero).image
    }
}
