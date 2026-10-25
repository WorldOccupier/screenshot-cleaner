import CoreServices
import Foundation

public enum ScreenshotScanner {
    private static let keys: Set<URLResourceKey> = [.isRegularFileKey, .creationDateKey, .totalFileAllocatedSizeKey]
    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff"]
    private static let namePattern = try! NSRegularExpression(
        pattern: #"^(Screenshot|Screen Shot|Screen Recording|CleanShot) \d{4}-\d{2}-\d{2}"#
    )

    /// Where macOS saves screenshots: the user's custom location, or the Desktop.
    public static func defaultLocation() -> URL {
        if let path = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
    }

    /// Shallow scan of `folder` for screenshots created before `cutoff`, oldest first.
    public static func scan(
        folder: URL,
        olderThan cutoff: Date = .distantFuture,
        includeRecordings: Bool = false,
        isScreenCapture: (URL) -> Bool = spotlightSaysScreenCapture
    ) -> [Screenshot] {
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
            )
        } catch {
            Log.scan.error("Couldn't read \(folder.path, privacy: .private): \(error.localizedDescription, privacy: .public)")
            return []
        }

        var result: [Screenshot] = []
        for url in urls {
            let ext = url.pathExtension.lowercased()
            guard imageExtensions.contains(ext) || (includeRecordings && ext == "mov"),
                  let values = try? url.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  let created = values.creationDate,
                  created < cutoff,
                  isScreenCapture(url) || hasScreenshotName(url.lastPathComponent)
            else { continue }
            result.append(Screenshot(url: url, created: created, bytes: Int64(values.totalFileAllocatedSize ?? 0)))
        }
        Log.scan.debug("Found \(result.count, privacy: .public) screenshots in \(folder.path, privacy: .private)")
        return result.sorted { $0.created < $1.created }
    }

    public static func hasScreenshotName(_ name: String) -> Bool {
        namePattern.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
    }

    /// macOS tags every screenshot with kMDItemIsScreenCapture, regardless of locale or rename.
    public static func spotlightSaysScreenCapture(_ url: URL) -> Bool {
        guard let item = MDItemCreateWithURL(nil, url as CFURL),
              let value = MDItemCopyAttribute(item, "kMDItemIsScreenCapture" as CFString)
        else { return false }
        return (value as? NSNumber)?.boolValue ?? false
    }
}
