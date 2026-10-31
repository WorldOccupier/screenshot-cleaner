import Foundation

/// The app's identity. When running inside the app bundle (including the bundled MCP server) the
/// version comes from `Info.plist`; the constants are the fallback for `swift run`, tests, and a
/// standalone MCP binary built from source.
public enum AppIdentity {
    public static let bundleIdentifier = "com.vatsa.ScreenshotCleaner"

    /// Keep in sync with `Resources/Info.plist`; `AppIdentityTests` checks that they match.
    public static let fallbackVersion = "0.2.0"

    public static var version: String {
        let bundle = Bundle.main
        guard bundle.bundleIdentifier == bundleIdentifier,
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !version.isEmpty
        else { return fallbackVersion }
        return version
    }
}
