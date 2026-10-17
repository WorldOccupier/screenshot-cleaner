import XCTest
@testable import CleanerCore

final class DeckTests: XCTestCase {
    private let card = Deck.travelPerCard

    // MARK: Following a gesture

    func testFollowTracksFingerProportionally() {
        var deck = Deck(count: 5)
        deck.settle(to: 2)
        deck.follow(travel: card / 2)
        XCTAssertEqual(deck.progress, 0.5, accuracy: 1e-9)
        deck.follow(travel: -card / 4)
        XCTAssertEqual(deck.progress, -0.25, accuracy: 1e-9)
    }

    func testFollowClampsToOneCard() {
        var deck = Deck(count: 5)
        deck.settle(to: 2)
        deck.follow(travel: card * 3)
        XCTAssertEqual(deck.progress, 1)
        deck.follow(travel: -card * 3)
        XCTAssertEqual(deck.progress, -1)
    }

    func testRubberBandsPastEitherEnd() {
        var deck = Deck(count: 3)
        deck.follow(travel: -card) // before the first card
        XCTAssertLessThan(deck.progress, 0)
        XCTAssertGreaterThan(deck.progress, -0.2, "resists strongly past the start")

        deck.settle(to: 2)
        deck.follow(travel: card) // past the last card
        XCTAssertGreaterThan(deck.progress, 0)
        XCTAssertLessThan(deck.progress, 0.2, "resists strongly past the end")
    }

    // MARK: Releasing

    func testShortDragSpringsBack() {
        var deck = Deck(count: 5)
        deck.settle(to: 2)
        deck.follow(travel: card * 0.2)
        deck.release()
        XCTAssertEqual(deck.index, 2)
        XCTAssertEqual(deck.progress, 0)
    }

    func testLongDragCommitsInItsDirection() {
        var deck = Deck(count: 5)
        deck.settle(to: 2)
        deck.follow(travel: card * 0.5)
        deck.release()
        XCTAssertEqual(deck.index, 3)

        deck.follow(travel: -card * 0.5)
        deck.release()
        XCTAssertEqual(deck.index, 2)
        XCTAssertEqual(deck.progress, 0)
    }

    func testFastFlickCommitsEvenWhenShort() {
        var deck = Deck(count: 5)
        deck.follow(travel: card * 0.1)
        deck.release(predictedTravel: card * 0.8)
        XCTAssertEqual(deck.index, 1)
    }

    func testReleasePastEndStaysOnLastCard() {
        var deck = Deck(count: 2)
        deck.settle(to: 1)
        deck.follow(travel: card * 5)
        deck.release(predictedTravel: card * 5)
        XCTAssertEqual(deck.index, 1)
        XCTAssertEqual(deck.progress, 0)
    }

    // MARK: Settling and list changes

    func testSettleClampsToValidRange() {
        var deck = Deck(count: 3)
        deck.settle(to: 10)
        XCTAssertEqual(deck.index, 2)
        deck.settle(to: -4)
        XCTAssertEqual(deck.index, 0)
    }

    func testUpdateCountKeepsPositionWhenPossible() {
        var deck = Deck(count: 6)
        deck.settle(to: 3)
        deck.update(count: 8)
        XCTAssertEqual(deck.index, 3)
        deck.update(count: 2)
        XCTAssertEqual(deck.index, 1)
        deck.update(count: 0)
        XCTAssertEqual(deck.index, 0)
    }

    func testUpdateCountCancelsLiveGesture() {
        var deck = Deck(count: 4)
        deck.follow(travel: card / 2)
        deck.update(count: 4)
        XCTAssertEqual(deck.progress, 0)
    }

    // MARK: Rendering window

    func testVisibleWindowIsTwoCardsEachSide() {
        var deck = Deck(count: 10)
        deck.settle(to: 5)
        XCTAssertEqual(deck.visible.map(\.index), [3, 4, 5, 6, 7])
        XCTAssertEqual(deck.visible.map(\.offset), [-2, -1, 0, 1, 2])
    }

    func testVisibleWindowTruncatesAtEdges() {
        var deck = Deck(count: 10)
        XCTAssertEqual(deck.visible.map(\.offset), [0, 1, 2])
        deck.settle(to: 9)
        XCTAssertEqual(deck.visible.map(\.offset), [-2, -1, 0])
        XCTAssertEqual(Deck(count: 0).visible.count, 0)
        XCTAssertEqual(Deck(count: 1).visible.map(\.index), [0])
    }

    func testPositionShiftsWithProgress() {
        var deck = Deck(count: 5)
        deck.settle(to: 2)
        deck.follow(travel: card * 0.4)
        XCTAssertEqual(deck.position(ofOffset: 0), -0.4, accuracy: 1e-9)
        XCTAssertEqual(deck.position(ofOffset: 1), 0.6, accuracy: 1e-9)
    }

    func testCounterText() {
        var deck = Deck(count: 6)
        XCTAssertEqual(deck.counterText, "1 of 6")
        deck.settle(to: 5)
        XCTAssertEqual(deck.counterText, "6 of 6")
        XCTAssertEqual(Deck(count: 1).counterText, " ", "blank but space-reserving")
        XCTAssertEqual(Deck(count: 0).counterText, " ")
    }
}

final class CardPoseTests: XCTestCase {
    func testFrontCardIsUpright() {
        let pose = CardPose(position: 0)
        XCTAssertEqual(pose, CardPose(position: -0.0))
        XCTAssertEqual(pose.x, 0)
        XCTAssertEqual(pose.rotation, 0)
        XCTAssertEqual(pose.scale, 1)
        XCTAssertEqual(pose.brightness, 0)
        XCTAssertEqual(pose.opacity, 1)
        XCTAssertEqual(pose.zIndex, 0)
    }

    func testNeighboursFanSymmetrically() {
        let left = CardPose(position: -1), right = CardPose(position: 1)
        XCTAssertEqual(left.x, -right.x)
        XCTAssertEqual(left.rotation, -right.rotation)
        XCTAssertEqual(left.y, right.y)
        XCTAssertGreaterThan(right.x, 0)
        XCTAssertGreaterThan(right.rotation, 0)
        XCTAssertLessThan(right.scale, 1)
        XCTAssertLessThan(right.brightness, 0)
        XCTAssertEqual(right.opacity, 1)
        XCTAssertLessThan(right.zIndex, CardPose(position: 0).zIndex)
    }

    func testPreloadedCardsAreHidden() {
        XCTAssertEqual(CardPose(position: 2).opacity, 0)
        XCTAssertEqual(CardPose(position: -2).opacity, 0)
        XCTAssertEqual(CardPose(position: 1.5).opacity, 0.5, accuracy: 1e-9, "fades in as it approaches")
    }

    func testDepthEffectsSaturateBeyondOneCard() {
        XCTAssertEqual(CardPose(position: 1).scale, CardPose(position: 2).scale)
        XCTAssertEqual(CardPose(position: 1).brightness, CardPose(position: 2).brightness)
    }
}

final class ThumbnailLayoutTests: XCTestCase {
    func testOrdinaryScreenshotsFill() {
        XCTAssertFalse(ThumbnailLayout.shouldFit(width: 2880, height: 1800))
        XCTAssertFalse(ThumbnailLayout.shouldFit(width: 800, height: 1200))
    }

    func testSliversAndTallCapturesFit() {
        XCTAssertTrue(ThumbnailLayout.shouldFit(width: 74, height: 4))
        XCTAssertTrue(ThumbnailLayout.shouldFit(width: 300, height: 2000))
    }

    func testZeroHeightDoesNotCrash() {
        XCTAssertTrue(ThumbnailLayout.shouldFit(width: 10, height: 0))
    }
}
