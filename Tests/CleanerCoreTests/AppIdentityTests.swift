import XCTest
@testable import CleanerCore

final class AppIdentityTests: XCTestCase {
    /// `AppIdentity` falls back to constants when there is no app bundle. Keep them in sync with
    /// the plist that `build.sh` copies into the app.
    func testFallbackMatchesTheBundledInfoPlist() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CleanerCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // package root
        let data = try Data(contentsOf: root.appendingPathComponent("Resources/Info.plist"))
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, AppIdentity.bundleIdentifier)
        XCTAssertEqual(plist["CFBundleShortVersionString"] as? String, AppIdentity.fallbackVersion)
    }

    func testVersionFallsBackOutsideTheAppBundle() {
        guard Bundle.main.bundleIdentifier != AppIdentity.bundleIdentifier else { return }
        XCTAssertEqual(AppIdentity.version, AppIdentity.fallbackVersion)
    }
}
