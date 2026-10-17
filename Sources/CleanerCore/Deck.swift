import Foundation

/// State of the flip-through card stack: which card is in front, and how far a live gesture has dragged it.
public struct Deck: Equatable, Sendable {
    /// Points of finger travel that equal one full card.
    public static let travelPerCard: Double = 110
    /// Cards rendered on each side of the front one. Two, so the next card is ready before it slides in.
    public static let renderRadius = 2

    public private(set) var count: Int
    public private(set) var index = 0
    /// Fractional distance travelled toward the next (+) or previous (−) card during a live gesture, in −1...1.
    public private(set) var progress: Double = 0

    public init(count: Int = 0) {
        self.count = count
    }

    private var lastIndex: Int { max(count - 1, 0) }

    /// Keeps the position valid when the underlying list changes.
    public mutating func update(count: Int) {
        self.count = count
        index = min(index, lastIndex)
        progress = 0
    }

    /// Tracks the finger 1:1, rubber-banding when pulling past either end.
    public mutating func follow(travel: Double) {
        var p = travel / Self.travelPerCard
        let pastEnd = (p > 0 && index >= lastIndex) || (p < 0 && index <= 0)
        if pastEnd { p = p / (1 + abs(p) * 4) * 0.5 }
        progress = min(max(p, -1), 1)
    }

    /// Commits to the neighbouring card if the gesture went far (or fast) enough; otherwise springs back.
    public mutating func release(predictedTravel: Double = 0) {
        let projected = predictedTravel / Self.travelPerCard
        let committed = abs(progress) > 0.3 || abs(projected) > 0.6
        let direction = committed ? (progress + projected > 0 ? 1 : -1) : 0
        settle(to: index + direction)
    }

    public mutating func settle(to target: Int) {
        index = min(max(target, 0), lastIndex)
        progress = 0
    }

    /// Indices of the cards to render, each with its offset from the front card.
    public var visible: [(index: Int, offset: Int)] {
        guard count > 0 else { return [] }
        let range = max(index - Self.renderRadius, 0)...min(index + Self.renderRadius, lastIndex)
        return range.map { ($0, $0 - index) }
    }

    /// Continuous position of the card at `offset`: 0 is front, ±1 the fanned neighbours, ±2 hidden just beyond.
    public func position(ofOffset offset: Int) -> Double {
        Double(offset) - progress
    }

    /// Counter text below the stack; blank (but space-reserving) when there's nothing to page through.
    public var counterText: String {
        count > 1 ? "\(index + 1) of \(count)" : " "
    }
}

/// How a card is drawn at a given continuous deck position.
public struct CardPose: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let rotation: Double
    public let scale: Double
    public let brightness: Double
    public let opacity: Double
    public let zIndex: Double

    public init(position t: Double) {
        let depth = min(abs(t), 1)
        x = t * 22
        y = abs(t) * 5
        rotation = t * 8
        scale = 1 - 0.05 * depth
        brightness = -0.08 * depth
        opacity = min(max(2 - abs(t), 0), 1)
        zIndex = -abs(t)
    }
}

/// Whether a thumbnail should be shown whole (letterboxed) rather than cropped to fill its card.
public enum ThumbnailLayout {
    /// Aspect ratios outside this range (slivers, very tall captures) would be a blurry crop.
    public static let fillableAspect: ClosedRange<Double> = 0.4...3

    public static func shouldFit(width: Int, height: Int) -> Bool {
        !fillableAspect.contains(Double(width) / Double(max(height, 1)))
    }
}
