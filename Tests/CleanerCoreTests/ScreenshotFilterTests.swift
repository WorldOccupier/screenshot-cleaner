import XCTest
@testable import CleanerCore

final class ScreenshotFilterTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func shot(_ name: String, daysOld: Double, bytes: Int64 = 100) -> Screenshot {
        Screenshot(url: URL(fileURLWithPath: "/tmp/\(name).png"), created: now.addingTimeInterval(-daysOld * 86_400), bytes: bytes)
    }

    func testZeroDaysMeansAnyAge() {
        let shots = [shot("a", daysOld: 0.001), shot("b", daysOld: 30)]
        XCTAssertEqual(shots.olderThan(days: 0, now: now).count, 2)
    }
}
