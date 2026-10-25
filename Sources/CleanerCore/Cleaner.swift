import Foundation

public enum Cleaner {
    public struct Result: Sendable, Equatable {
        public var count = 0
        public var bytes: Int64 = 0

        public init(count: Int = 0, bytes: Int64 = 0) {
            self.count = count
            self.bytes = bytes
        }
    }

    public typealias Remover = @Sendable (URL) throws -> Void

    /// Moves files to the Trash (never deletes outright), so everything is recoverable.
    public static let moveToTrash: Remover = { try FileManager.default.trashItem(at: $0, resultingItemURL: nil) }

    /// Removes each item, counting only the ones that succeed. Failures are logged, not thrown:
    /// one locked file must not stop the rest of the batch.
    public static func trash(_ items: [Screenshot], using remove: Remover = moveToTrash) -> Result {
        var result = Result()
        for item in items {
            do {
                try remove(item.url)
                result.count += 1
                result.bytes += item.bytes
            } catch {
                Log.clean.error("Couldn't move \(item.url.lastPathComponent, privacy: .private) to the Trash: \(error.localizedDescription, privacy: .public)")
            }
        }
        if !items.isEmpty {
            Log.clean.info("Moved \(result.count, privacy: .public) of \(items.count, privacy: .public) screenshots to the Trash (\(result.bytes, privacy: .public) bytes)")
        }
        return result
    }
}
