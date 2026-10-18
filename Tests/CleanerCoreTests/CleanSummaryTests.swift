import XCTest
@testable import CleanerCore

final class CleanSummaryTests: XCTestCase {
    private func shots(_ count: Int, bytes: Int64 = 1_000) -> [Screenshot] {
        (0..<count).map { Screenshot(url: URL(fileURLWithPath: "/tmp/\($0).png"), created: .distantPast, bytes: bytes) }
    }

    func testOneOfSeveralStillPluralises() {
        // Reads as "1 / of 2 screenshots", not "of 2 screenshot".
        XCTAssertEqual(CleanSummary(cleanable: shots(1), totalCount: 2, lastCleaned: nil).primary, "of 2 screenshots")
    }

    func testFailedCleanDoesNotClaimSpaceFreed() {
        let summary = CleanSummary(cleanable: [], totalCount: 0, lastCleaned: .init(count: 0, bytes: 0))
        XCTAssertEqual(summary.primary, "Nothing to clean")
    }
}
