import Foundation

public struct Screenshot: Identifiable, Hashable, Sendable {
    public let url: URL
    public let created: Date
    public let bytes: Int64
    public var id: URL { url }

    public init(url: URL, created: Date, bytes: Int64) {
        self.url = url
        self.created = created
        self.bytes = bytes
    }
}

extension Array where Element == Screenshot {
    /// Screenshots created more than `days` days before `now`. `days == 0` means any age.
    public func olderThan(days: Int, now: Date = Date()) -> [Screenshot] {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
        return filter { $0.created < cutoff }
    }

    public var totalBytes: Int64 { reduce(0) { $0 + $1.bytes } }
}
