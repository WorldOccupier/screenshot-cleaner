import CleanerCore
import XCTest

final class AgeOptionTests: XCTestCase {
    func testClampsToThePickerRange() {
        XCTAssertEqual(AgeOption.clamp(0), 1)
        XCTAssertEqual(AgeOption.clamp(1), 1)
        XCTAssertEqual(AgeOption.clamp(7), 7)
        XCTAssertEqual(AgeOption.clamp(30), 30)
        XCTAssertEqual(AgeOption.clamp(31), 30)
    }

    func testCaptionForAllAndDays() {
        XCTAssertEqual(AgeOption.caption(forDays: 0), "Any age")
        XCTAssertEqual(AgeOption.caption(forDays: 7), "Older than")
    }
}
