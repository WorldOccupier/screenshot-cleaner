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

    // MARK: Helpers

    /// Distance from a point to the front card's rounded outer edge (negative inside).
    private func distanceOutsideFrontCard(_ p: CGPoint) -> CGFloat {
        let radius = G.cornerRadius + G.line / 2
        let core = G.frontOuterRect.insetBy(dx: radius, dy: radius)
        let dx = max(core.minX - p.x, 0, p.x - core.maxX)
        let dy = max(core.minY - p.y, 0, p.y - core.maxY)
        return hypot(dx, dy) - radius
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
}
