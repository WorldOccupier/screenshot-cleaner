import XCTest
@testable import CleanerCore

final class AutoCleanPolicyTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testDueWhenNeverRun() {
        XCTAssertTrue(AutoCleanPolicy.isDue(lastRun: nil, now: now))
    }

    func testRunsAtMostOncePerDay() {
        XCTAssertFalse(AutoCleanPolicy.isDue(lastRun: now.addingTimeInterval(-3_600), now: now))
        XCTAssertFalse(AutoCleanPolicy.isDue(lastRun: now.addingTimeInterval(-86_399), now: now))
        XCTAssertTrue(AutoCleanPolicy.isDue(lastRun: now.addingTimeInterval(-86_400), now: now))
        XCTAssertTrue(AutoCleanPolicy.isDue(lastRun: now.addingTimeInterval(-7 * 86_400), now: now))
    }

    func testNeverCleansAnythingYoungerThanADay() {
        XCTAssertEqual(AutoCleanPolicy.ageDays(forSelection: 0), 1) // "All"
        XCTAssertEqual(AutoCleanPolicy.ageDays(forSelection: 1), 1)
        XCTAssertEqual(AutoCleanPolicy.ageDays(forSelection: 7), 7)
        XCTAssertEqual(AutoCleanPolicy.ageDays(forSelection: 30), 30)
    }
}
