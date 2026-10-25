import CleanerCore
import Foundation

/// The tools agents can call. Replies are short plain text: a summary costs one line, not a file listing.
public struct ScreenshotTools {
    public struct Reply: Equatable {
        public let text: String
        public var isError = false
    }

    let folder: URL
    let defaultAgeDays: Int
    let includeRecordings: Bool
    let now: () -> Date
    let remove: Cleaner.Remover

    init(folder: URL, defaultAgeDays: Int, includeRecordings: Bool = false, now: @escaping () -> Date = Date.init, remove: @escaping Cleaner.Remover = Cleaner.moveToTrash) {
        self.folder = folder
        self.defaultAgeDays = defaultAgeDays
        self.includeRecordings = includeRecordings
        self.now = now
        self.remove = remove
    }

    /// The real screenshot folder, defaulting to the age picked in the app.
    public static func live() -> ScreenshotTools {
        // Bundled inside the app, the server shares its defaults; run from source, it reads the app's domain.
        let appDomain = AppIdentity.bundleIdentifier
        let defaults = Bundle.main.bundleIdentifier == appDomain ? .standard : UserDefaults(suiteName: appDomain)
        let saved = defaults?.object(forKey: "ageDays") as? Int
        return ScreenshotTools(
            folder: ScreenshotScanner.defaultLocation(),
            defaultAgeDays: saved ?? AgeOption.default.days,
            includeRecordings: defaults?.bool(forKey: "includeRecordings") ?? false
        )
    }

    // MARK: Definitions

    /// Descriptions are deliberately terse: they're sent to the model on every session.
    var definitions: [[String: Any]] {
        let age: [String: Any] = [
            "type": "integer", "minimum": 0,
            "description": "Only screenshots older than this many days. 0 = any age. Default \(defaultAgeDays).",
        ]
        return [
            [
                "name": "screenshots_summary",
                "description": "Count and size of screenshots in the macOS screenshot folder, and how many are older than an age. One line.",
                "inputSchema": ["type": "object", "properties": ["older_than_days": age]],
                "annotations": ["readOnlyHint": true],
            ],
            [
                "name": "list_screenshots",
                "description": "Screenshots older than an age, oldest first: date, size, file name per line.",
                "inputSchema": ["type": "object", "properties": [
                    "older_than_days": age,
                    "limit": ["type": "integer", "minimum": 1, "maximum": 500, "description": "Max lines. Default 20."],
                ]],
                "annotations": ["readOnlyHint": true],
            ],
            [
                "name": "clean_screenshots",
                "description": "Move screenshots to the Trash (recoverable). Requires older_than_days, files, or both.",
                "inputSchema": ["type": "object", "properties": [
                    "older_than_days": ["type": "integer", "minimum": 0, "description": "Move screenshots older than this many days. 0 = any age."],
                    "files": ["type": "array", "items": ["type": "string"], "description": "File names from list_screenshots."],
                ]],
                "annotations": ["readOnlyHint": false, "destructiveHint": true, "idempotentHint": true],
            ],
        ]
    }

    // MARK: Calls

    /// Runs a tool. Bad arguments come back as an error reply (the model can fix and retry); an unknown tool throws.
    func call(_ name: String, arguments: [String: Any]) throws -> Reply {
        do {
            switch name {
            case "screenshots_summary": return Reply(text: try summary(arguments))
            case "list_screenshots": return Reply(text: try list(arguments))
            case "clean_screenshots": return Reply(text: try clean(arguments))
            default: throw RPCError.invalidParams("Unknown tool: \(name)")
            }
        } catch let error as ToolError {
            return Reply(text: error.message, isError: true)
        }
    }

    private func summary(_ args: [String: Any]) throws -> String {
        let days = try Arguments(args).int("older_than_days", in: 0...36_500) ?? defaultAgeDays
        let all = try scan()
        let old = all.olderThan(days: days, now: now())
        return Report.summary(folder: folder, all: all, old: old, days: days)
    }

    private func list(_ args: [String: Any]) throws -> String {
        let arguments = Arguments(args)
        let days = try arguments.int("older_than_days", in: 0...36_500) ?? defaultAgeDays
        let limit = try arguments.int("limit", in: 1...500) ?? 20
        return Report.list(folder: folder, old: try scan().olderThan(days: days, now: now()), days: days, limit: limit)
    }

    private func clean(_ args: [String: Any]) throws -> String {
        let arguments = Arguments(args)
        let days = try arguments.int("older_than_days", in: 0...36_500)
        let files = try arguments.strings("files")
        guard days != nil || files != nil else {
            throw ToolError(message: "Give older_than_days, files, or both. Nothing was moved.")
        }
        var batch = try scan()
        if let days { batch = batch.olderThan(days: days, now: now()) }
        var skipped: [String] = []
        if let files {
            let byName = Dictionary(batch.map { ($0.url.lastPathComponent, $0) }, uniquingKeysWith: { a, _ in a })
            skipped = files.filter { byName[$0] == nil }
            batch = Array(Set(files)).compactMap { byName[$0] }
        }
        let result = Cleaner.trash(batch, using: remove)
        return Report.cleaned(result, attempted: batch.count, skipped: skipped, folder: folder, days: days)
    }

    /// Scans the folder, failing loudly when it can't be read: an empty result would wrongly say "no screenshots".
    private func scan() throws -> [Screenshot] {
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        } catch {
            Log.mcp.error("Couldn't read \(folder.path, privacy: .private): \(error.localizedDescription, privacy: .public)")
            throw ToolError(message: "Can't read \(Report.path(folder)). Allow access in System Settings › Privacy & Security › Files and Folders for the app running this server.")
        }
        return ScreenshotScanner.scan(folder: folder, includeRecordings: includeRecordings)
    }
}

/// A problem the model can act on (bad arguments, unreadable folder), reported back as an error reply.
struct ToolError: Error {
    let message: String
}

private struct Arguments {
    let values: [String: Any]
    init(_ values: [String: Any]) { self.values = values }

    func int(_ key: String, in range: ClosedRange<Int>) throws -> Int? {
        guard let raw = values[key], !(raw is NSNull) else { return nil }
        guard let number = raw as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
              let value = Int(exactly: number.doubleValue), range.contains(value)
        else { throw ToolError(message: "\(key) must be a whole number from \(range.lowerBound) to \(range.upperBound).") }
        return value
    }

    func strings(_ key: String) throws -> [String]? {
        guard let raw = values[key], !(raw is NSNull) else { return nil }
        guard let list = raw as? [String] else { throw ToolError(message: "\(key) must be a list of file names.") }
        return list
    }
}
