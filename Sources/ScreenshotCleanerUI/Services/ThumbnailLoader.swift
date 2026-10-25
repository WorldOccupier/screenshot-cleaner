import AVFoundation
import CleanerCore
import CoreGraphics
import Foundation
import ImageIO

enum ThumbnailLoader {
    /// Decoded thumbnails survive a card leaving the deck's render window, so flipping back is instant.
    /// The cache is bounded by both item count and decoded pixel memory.
    private static let cache = ThumbnailCache()

    /// Decodes a downsampled thumbnail with ImageIO, off the main thread. Only the needed pixels are decoded.
    /// Results are cached by file identity, and decoding stops when the requesting view goes away.
    static func load(_ url: URL, maxPixels: CGFloat) async -> CGImage? {
        let key = ThumbnailCache.Key(url: url, maxPixels: maxPixels)
        if let cached = cache.image(for: key) { return cached }

        let task = Task.detached(priority: .utility) {
            guard !Task.isCancelled else { return nil as CGImage? }
            let image: CGImage?
            if url.pathExtension.lowercased() == "mov" {
                image = await firstFrame(url, maxPixels: maxPixels)
            } else {
                image = decode(url, maxPixels: maxPixels)
            }
            // Cache even when the view has since disappeared: the decode already happened.
            if let image { cache.insert(image, for: key) }
            return image
        }

        let image = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        if image == nil, !Task.isCancelled {
            Log.thumbnails.debug("Couldn't decode a thumbnail for \(url.lastPathComponent, privacy: .private)")
        }
        return Task.isCancelled ? nil : image
    }

    private static func decode(_ url: URL, maxPixels: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// Screen recordings: grab the first frame with AVFoundation, since ImageIO can't read video.
    private static func firstFrame(_ url: URL, maxPixels: CGFloat) async -> CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixels, height: maxPixels)
        return try? await generator.image(at: .zero).image
    }
}

/// Bounded, thread-safe storage for decoded thumbnails.
private final class ThumbnailCache: @unchecked Sendable {
    private let cache = NSCache<NSString, CGImage>()

    init() {
        cache.countLimit = 256
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    func image(for key: Key) -> CGImage? {
        cache.object(forKey: key.cacheKey)
    }

    func insert(_ image: CGImage, for key: Key) {
        cache.setObject(image, forKey: key.cacheKey, cost: image.bytesPerRow * image.height)
    }

    /// Identity includes the path, requested size, and the file's mtime and size, so a screenshot
    /// replaced in place is decoded again instead of serving a stale image.
    struct Key: Hashable, Sendable {
        private let path: String
        private let maxPixels: Int
        private let modified: TimeInterval
        private let fileSize: Int

        init(url: URL, maxPixels: CGFloat) {
            path = url.path
            self.maxPixels = Int(maxPixels.rounded())
            // FileManager, not URL.resourceValues: a URL caches resource values, which would hide
            // a file replaced in place. This is one stat per card.
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            modified = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            fileSize = (attributes?[.size] as? NSNumber)?.intValue ?? 0
        }

        var cacheKey: NSString {
            "\(path)|\(maxPixels)|\(modified)|\(fileSize)" as NSString
        }
    }
}
