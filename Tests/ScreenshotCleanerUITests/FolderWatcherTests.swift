import XCTest
@testable import ScreenshotCleanerUI

final class FolderWatcherTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func touch(_ name: String) throws {
        try Data("x".utf8).write(to: dir.appendingPathComponent(name))
    }

    func testNotifiesWhenAFileIsAdded() throws {
        let changed = expectation(description: "change")
        let watcher = FolderWatcher(url: dir, debounce: 0.05) { changed.fulfill() }
        XCTAssertNotNil(watcher)
        try touch("a.png")
        wait(for: [changed], timeout: 2)
    }

    func testDebouncesABurstIntoOneCall() throws {
        let changed = expectation(description: "one change")
        changed.assertForOverFulfill = true
        let watcher = FolderWatcher(url: dir, debounce: 0.3) { changed.fulfill() }
        for i in 0..<5 { try touch("\(i).png") }
        wait(for: [changed], timeout: 2)
        // Give any stray extra callbacks a chance to fire (over-fulfilling fails the test).
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        _ = watcher
    }
}
