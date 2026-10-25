import os

/// Unified logging, grouped by area. Watch it in Console.app, or with:
///
///     log stream --predicate 'subsystem == "com.vatsa.ScreenshotCleaner"' --level debug
///
/// Paths and file names are logged privately; counts and sizes are public.
public enum Log {
    private static let subsystem = AppIdentity.bundleIdentifier

    public static let scan = Logger(subsystem: subsystem, category: "scan")
    public static let clean = Logger(subsystem: subsystem, category: "clean")
    public static let watch = Logger(subsystem: subsystem, category: "watch")
    public static let store = Logger(subsystem: subsystem, category: "store")
    public static let mcp = Logger(subsystem: subsystem, category: "mcp")
    public static let thumbnails = Logger(subsystem: subsystem, category: "thumbnails")
}
