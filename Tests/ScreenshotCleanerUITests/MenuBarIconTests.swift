import AppKit
import XCTest
@testable import ScreenshotCleanerUI

/// Pixel-level checks on the menu bar glyph, rendered at 8× so anti-aliasing doesn't blur the assertions.
final class MenuBarIconTests: XCTestCase {
    private typealias G = MenuBarIcon.Geometry
    private var idle: Raster!
    private var pending: Raster!

    override func setUp() {
        idle = Raster(MenuBarIcon.make(filled: false))
        pending = Raster(MenuBarIcon.make(filled: true))
    }

    func testTemplateImagesSizedForTheMenuBar() {
        for image in [MenuBarIcon.idle, MenuBarIcon.pending] {
            XCTAssertTrue(image.isTemplate, "template images adapt to light and dark menu bars")
            XCTAssertEqual(image.size, G.canvas)
            XCTAssertLessThanOrEqual(image.size.height, 22, "fits the menu bar")
        }
    }

    func testImageSelectionByState() {
        XCTAssertIdentical(MenuBarIcon.image(hasPending: false), MenuBarIcon.idle)
        XCTAssertIdentical(MenuBarIcon.image(hasPending: true), MenuBarIcon.pending)
    }

    /// The gap around the front card is clear in both states, all the way round.
    func testGapAroundFrontCardIsClear() {
        for point in ring(around: G.frontOuterRect, distance: G.gapWidth / 2) {
            XCTAssertLessThan(idle.alpha(at: point), 0.2, "idle gap at \(point)")
            XCTAssertLessThan(pending.alpha(at: point), 0.2, "pending gap at \(point)")
        }
    }

    /// The gap is exactly `gapWidth` wide in both states: the back cards resume right after it.
    /// (This is what regressed before: the gap was too wide, and wider on the filled glyph.)
    func testGapIsExactlyTheSpecifiedWidthInBothStates() throws {
        for (name, raster) in [("idle", idle!), ("pending", pending!)] {
            let nearestBackCard = try XCTUnwrap(
                raster.points
                    .filter { raster.alpha(at: $0) > 0.5 }
                    .map(distanceOutsideFrontCard)
                    .filter { $0 > G.gapWidth / 2 } // skip the front card's own anti-aliased edge
                    .min()
            )
            XCTAssertEqual(nearestBackCard, G.gapWidth, accuracy: 0.2, "\(name) gap")
        }
    }

    /// Both states share the same front-card outer edge, so the glyph doesn't jump when the state changes.
    func testFrontCardOuterEdgeMatchesInBothStates() {
        for point in ring(around: G.frontOuterRect, distance: -G.line / 4) {
            XCTAssertGreaterThan(idle.alpha(at: point), 0.8, "idle edge at \(point)")
            XCTAssertGreaterThan(pending.alpha(at: point), 0.8, "pending edge at \(point)")
        }
    }

    /// Outside the front card the two states are pixel-identical: only the card's fill differs.
    func testStatesDifferOnlyInsideFrontCard() {
        let front = G.frontOuterRect
        let mismatches = idle.points.filter { point in
            !front.contains(point) && abs(idle.alpha(at: point) - pending.alpha(at: point)) > 0.05
        }
        XCTAssertEqual(mismatches.count, 0, "first mismatch: \(String(describing: mismatches.first))")
    }

    func testIdleFrontCardIsHollowAndPendingIsFilled() {
        let interior = CGPoint(x: G.frontCenter.x + 3.5, y: G.frontCenter.y - 2)
        XCTAssertLessThan(idle.alpha(at: interior), 0.2)
        XCTAssertGreaterThan(pending.alpha(at: interior), 0.8)
    }

    func testContentLinesDrawnOnIdleAndCutOutOfPending() {
        for rect in G.contentLineRects {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            XCTAssertGreaterThan(idle.alpha(at: center), 0.8, "line drawn at \(center)")
            XCTAssertLessThan(pending.alpha(at: center), 0.2, "line cut out at \(center)")
        }
        let first = G.contentLineRects[0], second = G.contentLineRects[1]
        XCTAssertGreaterThan(first.width, second.width, "long line above short line, like the app icon")
        XCTAssertGreaterThan(first.midY, second.midY)
    }

    func testBackCardsPeekOutOnBothSides() {
        let front = G.frontOuterRect.insetBy(dx: -G.gapWidth, dy: -G.gapWidth)
        let left = idle.opaqueCount { $0.x < front.minX }
        let right = idle.opaqueCount { $0.x > front.maxX }
        XCTAssertGreaterThan(left, 50)
        XCTAssertGreaterThan(right, 50)
        XCTAssertEqual(Double(left), Double(right), accuracy: Double(left) * 0.05, "fan is symmetric")
    }

    func testGlyphStaysInsideCanvas() {
        let edge = idle.opaqueCount { $0.x < 0.1 || $0.y < 0.1 || $0.x > G.canvas.width - 0.1 || $0.y > G.canvas.height - 0.1 }
        XCTAssertEqual(edge, 0, "nothing clipped at the canvas edge")
    }

    // MARK: Helpers

    /// Distance from a point to the front card's rounded outer edge (negative inside).
    private func distanceOutsideFrontCard(_ p: CGPoint) -> CGFloat {
        let radius = G.cornerRadius + G.line / 2
        let core = G.frontOuterRect.insetBy(dx: radius, dy: radius)
        let dx = max(core.minX - p.x, 0, p.x - core.maxX)
        let dy = max(core.minY - p.y, 0, p.y - core.maxY)
        return hypot(dx, dy) - radius
    }

    /// Points on a rectangle offset outward by `distance` (inward when negative), skipping rounded corners.
    private func ring(around rect: CGRect, distance d: CGFloat) -> [CGPoint] {
        let r = rect.insetBy(dx: -d, dy: -d)
        let corner = G.cornerRadius + G.line
        var points: [CGPoint] = []
        for x in stride(from: r.minX + corner, through: r.maxX - corner, by: 0.5) {
            points += [CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.maxY)]
        }
        for y in stride(from: r.minY + corner, through: r.maxY - corner, by: 0.5) {
            points += [CGPoint(x: r.minX, y: y), CGPoint(x: r.maxX, y: y)]
        }
        return points
    }
}

/// An image rasterised at a fixed scale, with alpha lookup in points (y-up, like the drawing code).
struct Raster {
    let scale: CGFloat
    private let rep: NSBitmapImageRep

    init(_ image: NSImage, scale: CGFloat = 8) {
        self.scale = scale
        rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width * scale), pixelsHigh: Int(image.size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        rep.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
    }

    func alpha(at point: CGPoint) -> CGFloat {
        let x = Int(point.x * scale), y = rep.pixelsHigh - 1 - Int(point.y * scale)
        guard (0..<rep.pixelsWide).contains(x), (0..<rep.pixelsHigh).contains(y) else { return 0 }
        return rep.colorAt(x: x, y: y)?.alphaComponent ?? 0
    }

    /// Every pixel centre, in points.
    var points: [CGPoint] {
        (0..<rep.pixelsHigh).flatMap { row in
            (0..<rep.pixelsWide).map { col in
                CGPoint(x: (CGFloat(col) + 0.5) / scale, y: (CGFloat(rep.pixelsHigh - 1 - row) + 0.5) / scale)
            }
        }
    }

    func opaqueCount(where include: (CGPoint) -> Bool) -> Int {
        points.filter { include($0) && alpha(at: $0) > 0.5 }.count
    }
}
