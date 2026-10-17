import CleanerCore
import XCTest
@testable import ScreenshotCleanerUI

@MainActor
final class StoreTests: XCTestCase {
    private var dir: URL!
    private var suiteName: String!
    private var preferences: Preferences!
    private let now = Date()

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        suiteName = "StoreTests-\(UUID().uuidString)"
        preferences = Preferences(defaults: UserDefaults(suiteName: suiteName)!)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    // MARK: Helpers

    @discardableResult
    private func screenshot(daysOld: Double, bytes: Int = 1) throws -> URL {
        let created = now.addingTimeInterval(-daysOld * 86_400)
        let stamp = Int(created.timeIntervalSince1970)
        var url = dir.appendingPathComponent("Screenshot 2026-01-01 at \(stamp).png")
        try Data(repeating: 0, count: bytes).write(to: url)
        var values = URLResourceValues()
        values.creationDate = created
        try url.setResourceValues(values)
        return url
    }

    /// A store over the temp folder whose "trash" simply deletes, so tests never touch the real Trash.
    private func makeStore(now: Date? = nil) -> Store {
        let clock = now ?? self.now
        return Store(folder: dir, preferences: preferences, now: { clock }, remove: { try FileManager.default.removeItem(at: $0) })
    }

    private func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    // MARK: Settings

    func testLoadsSettingsFromPreferences() {
        preferences.ageDays = 30
        preferences.autoClean = true
        let store = makeStore()
        XCTAssertEqual(store.ageDays, 30)
        XCTAssertTrue(store.autoClean)
    }

    func testDefaultsToOneWeekWithAutoCleanOff() {
        let store = makeStore()
        XCTAssertEqual(store.ageDays, 7)
        XCTAssertFalse(store.autoClean)
    }

    func testPersistsSettingChanges() {
        let store = makeStore()
        store.ageDays = 1
        store.autoClean = true
        XCTAssertEqual(preferences.ageDays, 1)
        XCTAssertTrue(preferences.autoClean)
    }

    // MARK: Scanning and filtering

    func testRefreshFindsAllAndFiltersByAge() async throws {
        try screenshot(daysOld: 0.1)
        try screenshot(daysOld: 3)
        try screenshot(daysOld: 10)
        let store = makeStore()
        await store.refresh()

        XCTAssertEqual(store.all.count, 3)
        store.ageDays = 7
        XCTAssertEqual(store.items.count, 1)
        store.ageDays = 1
        XCTAssertEqual(store.items.count, 2)
        store.ageDays = 0
        XCTAssertEqual(store.items.count, 3)
    }

    func testSummaryReflectsKeptScreenshots() async throws {
        try screenshot(daysOld: 0.1)
        try screenshot(daysOld: 10, bytes: 4096)
        let store = makeStore()
        store.ageDays = 7
        await store.refresh()
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.summary.primary, "of 2 screenshots")
        XCTAssertEqual(store.summary.secondary, CleanSummary.format(bytes: store.items.totalBytes))
    }

    // MARK: Cleaning

    func testCleanRemovesOnlyOldEnoughScreenshots() async throws {
        let fresh = try screenshot(daysOld: 0.1)
        let old = try screenshot(daysOld: 10, bytes: 2048)
        let store = makeStore()
        store.ageDays = 7
        await store.refresh()

        await store.clean()

        XCTAssertFalse(exists(old))
        XCTAssertTrue(exists(fresh))
        XCTAssertEqual(store.lastCleaned?.count, 1)
        XCTAssertEqual(store.all.map(\.url.lastPathComponent), [fresh.lastPathComponent], "rescanned after cleaning")
        XCTAssertFalse(store.isWorking)
        XCTAssertTrue(store.summary.primary.hasPrefix("Freed"))
    }

    func testCleanWithNothingToCleanDoesNothing() async throws {
        let fresh = try screenshot(daysOld: 0.1)
        let store = makeStore()
        await store.refresh()
        await store.clean()
        XCTAssertTrue(exists(fresh))
        XCTAssertNil(store.lastCleaned)
    }

    func testChangingAgeClearsFreedMessage() async throws {
        try screenshot(daysOld: 10)
        let store = makeStore()
        await store.refresh()
        await store.clean()
        XCTAssertNotNil(store.lastCleaned)
        store.ageDays = 30
        XCTAssertNil(store.lastCleaned)
    }

    // MARK: Auto-clean

    func testAutoCleanOffNeverCleans() async throws {
        let old = try screenshot(daysOld: 10)
        let store = makeStore()
        await store.heartbeatTick()
        XCTAssertTrue(exists(old))
        XCTAssertNil(preferences.lastAutoClean)
    }

    func testAutoCleanRunsWhenDueAndRecordsTheRun() async throws {
        let old = try screenshot(daysOld: 10)
        let store = makeStore()
        store.autoClean = true
        await store.heartbeatTick()
        XCTAssertFalse(exists(old))
        XCTAssertEqual(preferences.lastAutoClean, now)
    }

    func testAutoCleanRunsAtMostOnceADay() async throws {
        preferences.lastAutoClean = now.addingTimeInterval(-2 * 3_600)
        let old = try screenshot(daysOld: 10)
        let store = makeStore()
        store.autoClean = true
        await store.heartbeatTick()
        XCTAssertTrue(exists(old), "ran two hours ago, so not due")

        let tomorrow = makeStore(now: now.addingTimeInterval(86_400))
        tomorrow.autoClean = true
        await tomorrow.heartbeatTick()
        XCTAssertFalse(exists(old), "a day later it runs again")
    }

    func testAutoCleanRecordsRunEvenWhenNothingToClean() async throws {
        let store = makeStore()
        store.autoClean = true
        await store.heartbeatTick()
        XCTAssertEqual(preferences.lastAutoClean, now)
    }

    func testAutoCleanNeverRemovesScreenshotsYoungerThanADay() async throws {
        let fresh = try screenshot(daysOld: 0.5)
        let old = try screenshot(daysOld: 2)
        let store = makeStore()
        store.ageDays = 0 // "All"
        store.autoClean = true
        await store.heartbeatTick()
        XCTAssertTrue(exists(fresh))
        XCTAssertFalse(exists(old))
    }
}
