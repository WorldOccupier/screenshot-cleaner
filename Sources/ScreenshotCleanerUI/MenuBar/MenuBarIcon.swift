import AppKit

/// Menu bar glyph matching the app icon: a centred card with two cards fanned out behind it.
/// Outlined when there's nothing to clean, the front card filled when there is.
public enum MenuBarIcon {
    public static let idle = make(filled: false)
    public static let pending = make(filled: true)

    public static func image(hasPending: Bool) -> NSImage {
        hasPending ? pending : idle
    }

    /// Geometry in points (y-up). Proportions follow the app icon:
    /// card 380×260, side cards ±34% of card width, tilted 11°, scaled 0.94.
    enum Geometry {
        static let canvas = CGSize(width: 22, height: 16)
        static let cardSize = CGSize(width: 12, height: 8.2)
        static let cornerRadius: CGFloat = 2
        static let line: CGFloat = 1.2
        /// Clear space between the front card's outer edge and the cards behind it.
        static let gapWidth: CGFloat = 0.6
        static let frontCenter = CGPoint(x: 11, y: 8.9)
        static let sideOffset = CGPoint(x: 4.1, y: -1.5)
        static let sideRotation: CGFloat = 11
        static let sideScale: CGFloat = 0.94

        /// The front card's outer edge (its outline extends half a line past the path).
        static var frontOuterRect: CGRect {
            CGRect(
                x: frontCenter.x - cardSize.width / 2, y: frontCenter.y - cardSize.height / 2,
                width: cardSize.width, height: cardSize.height
            ).insetBy(dx: -line / 2, dy: -line / 2)
        }

        /// The two content lines on the front card: (y offset from the first line, length).
        static let contentLines: [(offset: CGFloat, length: CGFloat)] = [(0, 5.6), (2, 3.6)]
        static let contentLineHeight: CGFloat = 1
        static var contentLineRects: [CGRect] {
            let left = frontCenter.x - cardSize.width / 2 + 2.6
            let top = frontCenter.y + cardSize.height / 2 - 2.9
            return contentLines.map {
                CGRect(x: left, y: top - $0.offset - contentLineHeight / 2, width: $0.length, height: contentLineHeight)
            }
        }
    }

    static func make(filled: Bool) -> NSImage {
        typealias G = Geometry
        let image = NSImage(size: G.canvas, flipped: false) { _ in
            NSColor.black.set()
            for side in [-1.0, 1.0] {
                let center = CGPoint(x: G.frontCenter.x + side * G.sideOffset.x, y: G.frontCenter.y + G.sideOffset.y)
                let back = card(center: center, degrees: -side * G.sideRotation, scale: G.sideScale)
                back.lineWidth = G.line
                back.stroke()
            }

            let front = card(center: G.frontCenter, degrees: 0, scale: 1)
            // Knock the back cards out from under the front one: a thin, even gap past the front card's outer edge.
            withCompositing(.clear) {
                let gap = front.copy() as! NSBezierPath
                gap.lineWidth = G.line + 2 * G.gapWidth
                gap.stroke()
                gap.fill()
            }

            // Both states stroke the outline so the front card has the same outer edge either way.
            front.lineWidth = G.line
            front.stroke()
            if filled { front.fill() }

            // Content lines: drawn on the outline card, cut out of the filled one.
            withCompositing(filled ? .clear : .sourceOver) {
                for rect in G.contentLineRects {
                    NSBezierPath(roundedRect: rect, xRadius: G.contentLineHeight / 2, yRadius: G.contentLineHeight / 2).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func withCompositing(_ operation: NSCompositingOperation, _ draw: () -> Void) {
        let context = NSGraphicsContext.current
        let previous = context?.compositingOperation ?? .sourceOver
        context?.compositingOperation = operation
        draw()
        context?.compositingOperation = previous
    }

    private static func card(center: CGPoint, degrees: CGFloat, scale: CGFloat) -> NSBezierPath {
        let w = Geometry.cardSize.width * scale, h = Geometry.cardSize.height * scale
        let r = Geometry.cornerRadius
        let path = NSBezierPath(roundedRect: NSRect(x: -w / 2, y: -h / 2, width: w, height: h), xRadius: r, yRadius: r)
        var transform = AffineTransform(translationByX: center.x, byY: center.y)
        transform.rotate(byDegrees: degrees)
        path.transform(using: transform)
        return path
    }
}
