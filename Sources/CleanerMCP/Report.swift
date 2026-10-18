import CleanerCore
import Foundation

/// Compact plain-text replies. Every word here is a token the agent pays for.
enum Report {
    static func summary(folder: URL, all: [Screenshot], old: [Screenshot], days: Int) -> String {
        guard !all.isEmpty else { return "\(path(folder)): no screenshots." }
        let head = "\(path(folder)): \(count(all.count)), \(size(all.totalBytes))."
        guard let oldest = old.first else { return "\(head) None \(age(days))." }
        return "\(head) \(old.count) \(age(days)) (\(size(old.totalBytes))), oldest \(date(oldest.created))."
    }

    static func list(folder: URL, old: [Screenshot], days: Int, limit: Int) -> String {
        guard !old.isEmpty else { return "No screenshots \(age(days)) in \(path(folder))." }
        var lines = ["\(old.count) \(age(days)) in \(path(folder)), \(size(old.totalBytes)):"]
        lines += old.prefix(limit).map { "\(date($0.created))  \(size($0.bytes))  \($0.url.lastPathComponent)" }
        if old.count > limit { lines.append("…\(old.count - limit) more (raise limit to see them)") }
        return lines.joined(separator: "\n")
    }

    static func cleaned(_ result: Cleaner.Result, attempted: Int, skipped: [String], folder: URL, days: Int?) -> String {
        var lines: [String] = []
        if attempted == 0 && skipped.isEmpty {
            lines.append("Nothing to move: no screenshots \(days.map(age) ?? "matching") in \(path(folder)).")
        } else if result.count > 0 {
            lines.append("Moved \(count(result.count)) (\(size(result.bytes))) to the Trash.")
        } else if attempted == 0 {
            lines.append("Nothing moved.")
        }
        if result.count < attempted {
            lines.append("\(attempted - result.count) couldn't be moved (in use or no permission).")
        }
        if !skipped.isEmpty {
            lines.append("Skipped, not \(days.map { "screenshots \(age($0))" } ?? "screenshots") in \(path(folder)): \(skipped.joined(separator: ", ")).")
        }
        return lines.joined(separator: "\n")
    }

    static func age(_ days: Int) -> String {
        switch days {
        case 0: "of any age"
        case 1: "older than 1 day"
        default: "older than \(days) days"
        }
    }

    static func count(_ n: Int) -> String { n == 1 ? "1 screenshot" : "\(n) screenshots" }
    static func size(_ bytes: Int64) -> String { CleanSummary.format(bytes: bytes) }
    static func path(_ url: URL) -> String { (url.path as NSString).abbreviatingWithTildeInPath }

    static func date(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }
}
