import Foundation

/// When auto-clean runs and what it may remove.
public enum AutoCleanPolicy {
    /// Auto-clean runs at most once per this interval.
    public static let interval: TimeInterval = 86_400
    /// Auto-clean never removes anything younger than this, even when "All" is selected.
    public static let minimumAgeDays = 1

    public static func isDue(lastRun: Date?, now: Date) -> Bool {
        guard let lastRun else { return true }
        return now.timeIntervalSince(lastRun) >= interval
    }

    public static func ageDays(forSelection selected: Int) -> Int {
        max(selected, minimumAgeDays)
    }
}
