import XCTest
@testable import CleanerCore

final class CleanSummaryTests: XCTestCase {
    private func shots(_ count: Int, bytes: Int64 = 1_000) -> [Screenshot] {
        (0..<count).map { Screenshot(url: URL(fileURLWithPath: "/tmp/\($0).png"), created: .distantPast, bytes: bytes) }
    }

    func testSingularAndPlural() {
        XCTAssertEqual(CleanSummary(cleanable: shots(1), totalCount: 1, lastCleaned: nil).primary, "screenshot")
        XCTAssertEqual(CleanSummary(cleanable: shots(3), totalCount: 3, lastCleaned: nil).primary, "screenshots")
    }

    func testMentionsTotalWhenNewerOnesAreKept() {
        let summary = CleanSummary(cleanable: shots(2), totalCount: 6, lastCleaned: nil)
        XCTAssertEqual(summary.primary, "of 6 screenshots")
    }

    func testOneOfSeveralStillPluralises() {
        // Reads as "1 / of 2 screenshots", not "of 2 screenshot".
        XCTAssertEqual(CleanSummary(cleanable: shots(1), totalCount: 2, lastCleaned: nil).primary, "of 2 screenshots")
    }

    func testSecondaryLineIsTotalSizeOfCleanable() {
        let summary = CleanSummary(cleanable: shots(2, bytes: 250_000), totalCount: 2, lastCleaned: nil)
        XCTAssertEqual(summary.secondary, CleanSummary.format(bytes: 500_000))
    }

    func testNothingToClean() {
        let summary = CleanSummary(cleanable: [], totalCount: 0, lastCleaned: nil)
        XCTAssertEqual(summary.primary, "Nothing to clean")
        XCTAssertNil(summary.secondary)
    }

    func testNothingToCleanButNewerKept() {
        let summary = CleanSummary(cleanable: [], totalCount: 3, lastCleaned: nil)
        XCTAssertEqual(summary.secondary, "3 newer kept")
    }

    func testFreedAfterCleaning() {
        let summary = CleanSummary(cleanable: [], totalCount: 0, lastCleaned: .init(count: 4, bytes: 48_000_000))
        XCTAssertEqual(summary.primary, "Freed \(CleanSummary.format(bytes: 48_000_000))")
    }

    func testFailedCleanDoesNotClaimSpaceFreed() {
        let summary = CleanSummary(cleanable: [], totalCount: 0, lastCleaned: .init(count: 0, bytes: 0))
        XCTAssertEqual(summary.primary, "Nothing to clean")
    }
}
