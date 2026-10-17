import Foundation

/// The two lines of text under the big count in the popover.
public struct CleanSummary: Equatable, Sendable {
    public let primary: String
    /// Always rendered (as a blank line when nil) so the layout never changes height.
    public let secondary: String?

    public init(cleanable: [Screenshot], totalCount: Int, lastCleaned: Cleaner.Result?) {
        let newer = max(totalCount - cleanable.count, 0)
        if cleanable.isEmpty {
            if let done = lastCleaned, done.count > 0 {
                primary = "Freed \(Self.format(bytes: done.bytes))"
            } else {
                primary = "Nothing to clean"
            }
            secondary = newer > 0 ? "\(newer) newer kept" : nil
        } else {
            // Reads under the big count: "3 / screenshots", or "1 / of 2 screenshots" (noun agrees with the total).
            if newer > 0 {
                primary = "of \(totalCount) screenshots"
            } else {
                primary = cleanable.count == 1 ? "screenshot" : "screenshots"
            }
            secondary = Self.format(bytes: cleanable.totalBytes)
        }
    }

    public static func format(bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }
}
