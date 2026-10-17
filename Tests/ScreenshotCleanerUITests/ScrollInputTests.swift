import AppKit
import CleanerCore
import XCTest
@testable import ScreenshotCleanerUI

/// Converting real `NSEvent`s (built from CGEvents) into deck input.
final class ScrollInputTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    private func event(dy: Int32 = 0, dx: Int32 = 0, continuous: Bool, phase: Int64 = 0, momentum: Int64 = 0) -> NSEvent {
        let cg = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0)!
        cg.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        cg.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentum)
        return NSEvent(cgEvent: cg)!
    }

    // CGScrollPhase / CGMomentumScrollPhase raw values.
    private let began: Int64 = 1, changed: Int64 = 2, ended: Int64 = 4, cancelled: Int64 = 8, momentumContinue: Int64 = 2

    func testMouseWheelBecomesWheelInput() {
        let e = event(dy: -3, continuous: false)
        XCTAssertEqual(ScrollInput(e, now: now), .wheel(delta: -Double(e.scrollingDeltaY), at: now))
    }

    func testTrackpadPhases() {
        XCTAssertEqual(ScrollInput(event(continuous: true, phase: began), now: now), .began)
        let move = event(dy: -12, continuous: true, phase: changed)
        XCTAssertEqual(ScrollInput(move, now: now), .changed(delta: -Double(move.scrollingDeltaY)))
        XCTAssertEqual(ScrollInput(event(continuous: true, phase: ended), now: now), .ended)
        XCTAssertEqual(ScrollInput(event(continuous: true, phase: cancelled), now: now), .ended)
    }

    func testTrackpadMomentum() {
        XCTAssertEqual(ScrollInput(event(dy: -5, continuous: true, momentum: momentumContinue), now: now), .momentum)
    }

    func testDominantAxisWins() {
        let horizontal = event(dy: 2, dx: -20, continuous: true, phase: changed)
        XCTAssertEqual(ScrollInput(horizontal, now: now), .changed(delta: -Double(horizontal.scrollingDeltaX)))
    }
}
