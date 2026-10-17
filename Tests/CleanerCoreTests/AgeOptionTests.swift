import XCTest
@testable import CleanerCore

final class AgeOptionTests: XCTestCase {
    func testOptionsInDisplayOrder() {
        XCTAssertEqual(AgeOption.allCases.map(\.label), ["All", "1d", "1w", "1m"])
        XCTAssertEqual(AgeOption.allCases.map(\.days), [0, 1, 7, 30])
    }

    func testCaption() {
        XCTAssertEqual(AgeOption.caption(forDays: 0), "Any age")
        XCTAssertEqual(AgeOption.caption(forDays: 7), "Older than")
    }
}
