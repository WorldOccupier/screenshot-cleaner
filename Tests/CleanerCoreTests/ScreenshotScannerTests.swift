import XCTest
@testable import CleanerCore

final class ScreenshotScannerTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func make(_ name: String, daysOld: Double, in folder: URL? = nil) throws {
        var url = (folder ?? dir).appendingPathComponent(name)
        try Data("x".utf8).write(to: url)
        var values = URLResourceValues()
        values.creationDate = Date().addingTimeInterval(-daysOld * 86_400)
        try url.setResourceValues(values)
    }

    private func scan(olderThanDays days: Double = 0, recordings: Bool = false, spotlight: Bool = false) -> [String] {
        let cutoff = Date().addingTimeInterval(-days * 86_400)
        return ScreenshotScanner.scan(folder: dir, olderThan: cutoff, includeRecordings: recordings) { _ in spotlight }
            .map(\.url.lastPathComponent)
    }

    func testFindsOnlyOldScreenshotsOldestFirst() throws {
        try make("Screenshot 2026-01-01 at 9.41.22 AM.png", daysOld: 10)
        try make("Screen Shot 2020-01-01 at 1.00.00 PM.png", daysOld: 400)
        try make("Screenshot 2026-10-17 at 9.00.00 AM.png", daysOld: 1) // too new
        try make("holiday.png", daysOld: 30)                             // not a screenshot

        XCTAssertEqual(scan(olderThanDays: 7), [
            "Screen Shot 2020-01-01 at 1.00.00 PM.png",
            "Screenshot 2026-01-01 at 9.41.22 AM.png",
        ])
    }

    func testDefaultCutoffIncludesEveryScreenshot() throws {
        try make("Screenshot 2026-10-17 at 9.00.00 AM.png", daysOld: 0.01)
        let found = ScreenshotScanner.scan(folder: dir) { _ in false }
        XCTAssertEqual(found.count, 1)
    }

    func testRecordingsOnlyWhenRequested() throws {
        try make("Screen Recording 2026-01-01 at 1.00.00 PM.mov", daysOld: 30)
        XCTAssertEqual(scan(), [])
        XCTAssertEqual(scan(recordings: true), ["Screen Recording 2026-01-01 at 1.00.00 PM.mov"])
    }

    func testMetadataFlagCatchesRenamedScreenshots() throws {
        try make("renamed.png", daysOld: 30)
        XCTAssertEqual(scan(spotlight: true), ["renamed.png"])
        XCTAssertEqual(scan(spotlight: false), [])
    }

    func testIgnoresNonImagesHiddenFilesAndSubfolders() throws {
        try make("Screenshot 2026-01-01 at 9.00.00.txt", daysOld: 30)
        try make(".Screenshot 2026-01-01 at 9.00.00.png", daysOld: 30)
        let sub = dir.appendingPathComponent("Screenshot 2026-01-01 folder.png", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try make("Screenshot 2026-01-01 at 9.00.00.png", daysOld: 30, in: sub)
        XCTAssertEqual(scan(spotlight: true), [])
    }

    func testMissingFolderYieldsNothing() {
        let missing = dir.appendingPathComponent("nope")
        XCTAssertEqual(ScreenshotScanner.scan(folder: missing).count, 0)
    }

    func testScreenshotNamePattern() {
        XCTAssertTrue(ScreenshotScanner.hasScreenshotName("Screenshot 2026-10-17 at 21.36.43.png"))
        XCTAssertTrue(ScreenshotScanner.hasScreenshotName("Screen Shot 2019-01-01 at 1.00.00 PM.png"))
        XCTAssertTrue(ScreenshotScanner.hasScreenshotName("CleanShot 2026-01-01 at 10.00.00.png"))
        XCTAssertFalse(ScreenshotScanner.hasScreenshotName("Screenshot of my contract.png"))
        XCTAssertFalse(ScreenshotScanner.hasScreenshotName("My Screenshot 2026-10-17.png"))
    }
}
