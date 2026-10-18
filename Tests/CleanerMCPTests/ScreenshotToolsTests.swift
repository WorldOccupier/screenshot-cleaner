import CleanerCore
import XCTest
@testable import CleanerMCP

final class ScreenshotToolsTests: XCTestCase {
    private var dir: URL!
    private let now = Date()

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("mcp-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: Helpers

    @discardableResult
    private func file(_ name: String, daysOld: Double) throws -> URL {
        var url = dir.appendingPathComponent(name)
        try Data(repeating: 0, count: 10).write(to: url)
        var values = URLResourceValues()
        values.creationDate = now.addingTimeInterval(-daysOld * 86_400)
        try url.setResourceValues(values)
        return url
    }

    private func shot(_ n: Int, daysOld: Double) throws {
        try file("Screenshot 2026-01-\(String(format: "%02d", n)) at 10.00.00.png", daysOld: daysOld)
    }

    /// Tools over the temp folder whose "trash" simply deletes, so tests never touch the real Trash.
    private func tools(defaultAgeDays: Int = 7) -> ScreenshotTools {
        ScreenshotTools(folder: dir, defaultAgeDays: defaultAgeDays, now: { [now] in now }) {
            try FileManager.default.removeItem(at: $0)
        }
    }

    private func call(_ name: String, _ arguments: [String: Any] = [:], tools: ScreenshotTools? = nil) throws -> ScreenshotTools.Reply {
        try (tools ?? self.tools()).call(name, arguments: arguments)
    }

    private var remaining: [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []).sorted()
    }

    // MARK: Summary

    func testSummaryIsOneLineWithCountsAndOldest() throws {
        try shot(1, daysOld: 20)
        try shot(2, daysOld: 10)
        try shot(3, daysOld: 1)
        try file("notes.png", daysOld: 30)
        let text = try call("screenshots_summary").text
        XCTAssertFalse(text.contains("\n"))
        XCTAssertTrue(text.contains(": 3 screenshots,"), text)
        XCTAssertTrue(text.contains(" 2 older than 7 days ("), text)
        XCTAssertTrue(text.contains("oldest \(Report.date(now.addingTimeInterval(-20 * 86_400)))"), text)
    }

    // MARK: List

    func testListTruncatesAtLimit() throws {
        for n in 1...5 { try shot(n, daysOld: Double(10 + n)) }
        let lines = try call("list_screenshots", ["limit": 2]).text.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines.last, "…3 more (raise limit to see them)")
    }

    // MARK: Clean

    func testCleanByAgeMovesOnlyOldScreenshots() throws {
        try shot(1, daysOld: 20)
        try shot(2, daysOld: 1)
        try file("notes.png", daysOld: 30)
        let reply = try call("clean_screenshots", ["older_than_days": 7])
        XCTAssertFalse(reply.isError)
        XCTAssertTrue(reply.text.hasPrefix("Moved 1 screenshot ("), reply.text)
        XCTAssertEqual(remaining, ["Screenshot 2026-01-02 at 10.00.00.png", "notes.png"])
    }

    func testCleanRequiresAnExplicitSelection() throws {
        try shot(1, daysOld: 20)
        let reply = try call("clean_screenshots")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(remaining.count, 1, "never cleans on a default")
    }

    func testCleanByFilesSkipsAnythingThatIsNotAScreenshotInTheFolder() throws {
        try shot(1, daysOld: 20)
        try shot(2, daysOld: 1)
        try file("notes.png", daysOld: 30)
        let reply = try call("clean_screenshots", ["files": [
            "Screenshot 2026-01-02 at 10.00.00.png", "notes.png", "../Screenshot 2026-01-01 at 10.00.00.png",
        ]])
        XCTAssertTrue(reply.text.contains("Moved 1 screenshot"), reply.text)
        XCTAssertTrue(reply.text.contains("Skipped, not screenshots in "), reply.text)
        XCTAssertTrue(reply.text.contains("notes.png, ../Screenshot 2026-01-01 at 10.00.00.png"), reply.text)
        XCTAssertEqual(remaining, ["Screenshot 2026-01-01 at 10.00.00.png", "notes.png"])
    }

    // MARK: Arguments

    func testUnreadableFolderIsAnErrorNotZeroScreenshots() throws {
        let missing = ScreenshotTools(folder: dir.appendingPathComponent("gone"), defaultAgeDays: 7) { _ in }
        for name in ["screenshots_summary", "list_screenshots"] {
            let reply = try call(name, tools: missing)
            XCTAssertTrue(reply.isError, name)
            XCTAssertTrue(reply.text.hasPrefix("Can't read "), reply.text)
        }
        XCTAssertTrue(try call("clean_screenshots", ["older_than_days": 0], tools: missing).isError)
    }
}
