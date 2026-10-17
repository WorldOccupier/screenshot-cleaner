import XCTest
@testable import CleanerCore

final class ScreenshotFilterTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func shot(_ name: String, daysOld: Double, bytes: Int64 = 100) -> Screenshot {
        Screenshot(url: URL(fileURLWithPath: "/tmp/\(name).png"), created: now.addingTimeInterval(-daysOld * 86_400), bytes: bytes)
    }

    func testOlderThanUsesStrictCutoff() {
        let shots = [shot("a", daysOld: 0.5), shot("b", daysOld: 1), shot("c", daysOld: 1.01), shot("d", daysOld: 8)]
        XCTAssertEqual(shots.olderThan(days: 1, now: now).map(\.url.lastPathComponent), ["c.png", "d.png"])
        XCTAssertEqual(shots.olderThan(days: 7, now: now).map(\.url.lastPathComponent), ["d.png"])
    }

    func testZeroDaysMeansAnyAge() {
        let shots = [shot("a", daysOld: 0.001), shot("b", daysOld: 30)]
        XCTAssertEqual(shots.olderThan(days: 0, now: now).count, 2)
    }

    func testTotalBytes() {
        XCTAssertEqual([shot("a", daysOld: 1, bytes: 1_000), shot("b", daysOld: 1, bytes: 2_500)].totalBytes, 3_500)
        XCTAssertEqual([Screenshot]().totalBytes, 0)
    }
}
