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

    /// Removes each item, counting only the ones that succeed.
    public static func trash(_ items: [Screenshot], using remove: Remover = moveToTrash) -> Result {
        var result = Result()
        for item in items where (try? remove(item.url)) != nil {
            result.count += 1
            result.bytes += item.bytes
        }
        return result
    }
}
