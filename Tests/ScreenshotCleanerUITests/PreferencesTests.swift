import XCTest
@testable import ScreenshotCleanerUI

final class PreferencesTests: XCTestCase {
    private var suiteName: String!
    private var preferences: Preferences!

    override func setUp() {
        suiteName = "PreferencesTests-\(UUID().uuidString)"
        preferences = Preferences(defaults: UserDefaults(suiteName: suiteName)!)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testZeroAgeIsStoredNotTreatedAsMissing() {
        preferences.ageDays = 0 // "All"
        XCTAssertEqual(preferences.ageDays, 0)
    }
}
