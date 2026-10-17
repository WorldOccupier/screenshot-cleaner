import XCTest
@testable import CleanerCore

final class ScrollInterpreterTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    func testTrackpadGestureAccumulatesThenReleases() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.began), .ignore)
        XCTAssertTrue(scroll.isTracking)
        XCTAssertEqual(scroll.handle(.changed(delta: 10)), .follow(travel: 10))
        XCTAssertEqual(scroll.handle(.changed(delta: 15)), .follow(travel: 25))
        XCTAssertEqual(scroll.handle(.changed(delta: -5)), .follow(travel: 20))
        XCTAssertEqual(scroll.handle(.ended), .release)
        XCTAssertFalse(scroll.isTracking)
        XCTAssertEqual(scroll.travel, 0)
    }

    func testNewGestureStartsFromZero() {
        var scroll = ScrollInterpreter()
        _ = scroll.handle(.began)
        _ = scroll.handle(.changed(delta: 40))
        _ = scroll.handle(.ended)
        _ = scroll.handle(.began)
        XCTAssertEqual(scroll.handle(.changed(delta: 5)), .follow(travel: 5))
    }

    func testMomentumIsIgnored() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.momentum), .ignore)
    }

    func testStrayEndWithoutGestureIsIgnored() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.ended), .ignore)
    }

    func testWheelStepsInDirectionOfDelta() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.wheel(delta: 3, at: t0)), .step(1))
        XCTAssertEqual(scroll.handle(.wheel(delta: -3, at: t0.addingTimeInterval(1))), .step(-1))
    }

    func testWheelIsThrottled() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.wheel(delta: 1, at: t0)), .step(1))
        XCTAssertEqual(scroll.handle(.wheel(delta: 1, at: t0.addingTimeInterval(0.1))), .ignore)
        XCTAssertEqual(scroll.handle(.wheel(delta: 1, at: t0.addingTimeInterval(ScrollInterpreter.wheelThrottle + 0.01))), .step(1))
    }

    func testZeroWheelDeltaIsIgnored() {
        var scroll = ScrollInterpreter()
        XCTAssertEqual(scroll.handle(.wheel(delta: 0, at: t0)), .ignore)
    }
}
