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

    func testDefaults() {
        XCTAssertEqual(preferences.ageDays, Preferences.defaultAgeDays)
        XCTAssertFalse(preferences.autoClean)
        XCTAssertNil(preferences.lastAutoClean)
    }

    func testZeroAgeIsStoredNotTreatedAsMissing() {
        preferences.ageDays = 0 // "All"
        XCTAssertEqual(preferences.ageDays, 0)
    }

    func testRoundTrips() {
        let date = Date(timeIntervalSinceReferenceDate: 12_345)
        preferences.ageDays = 30
        preferences.autoClean = true
        preferences.lastAutoClean = date

        let reloaded = Preferences(defaults: UserDefaults(suiteName: suiteName)!)
        XCTAssertEqual(reloaded.ageDays, 30)
        XCTAssertTrue(reloaded.autoClean)
        XCTAssertEqual(reloaded.lastAutoClean, date)
    }
}
