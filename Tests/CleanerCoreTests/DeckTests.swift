import XCTest
@testable import CleanerCore

final class DeckTests: XCTestCase {
    private let card = Deck.travelPerCard

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
}
