import Foundation

/// A scroll event, reduced to what the deck cares about.
public enum ScrollInput: Equatable, Sendable {
    /// Trackpad fingers touched down.
    case began
    /// Trackpad fingers moved; positive means toward the next card.
    case changed(delta: Double)
    /// Trackpad fingers lifted (or the gesture was cancelled).
    case ended
    /// Inertial scrolling after the fingers lifted.
    case momentum
    /// A discrete mouse-wheel notch.
    case wheel(delta: Double, at: Date)
}

/// Turns raw scroll input into deck actions: trackpads drag the deck continuously, mouse wheels step it.
public struct ScrollInterpreter: Sendable {
    public enum Action: Equatable, Sendable {
        case ignore
        /// Move the deck to follow `travel` points of accumulated finger movement.
        case follow(travel: Double)
        /// Fingers lifted: let the deck settle.
        case release
        /// Step one card in the given direction.
        case step(Int)
    }

    /// Minimum time between mouse-wheel steps, so a fast spin doesn't blur through the deck.
    public static let wheelThrottle: TimeInterval = 0.35

    public private(set) var travel: Double = 0
    public private(set) var isTracking = false
    private var lastWheelStep = Date.distantPast

    public init() {}

    public mutating func handle(_ input: ScrollInput) -> Action {
        switch input {
        case .momentum:
            return .ignore // inertia is ignored; the deck settles with its own spring
        case .began:
            travel = 0
            isTracking = true
            return .ignore
        case .changed(let delta):
            travel += delta
            isTracking = true
            return .follow(travel: travel)
        case .ended:
            let wasTracking = isTracking
            travel = 0
            isTracking = false
            return wasTracking ? .release : .ignore
        case .wheel(let delta, let time):
            guard delta != 0, time.timeIntervalSince(lastWheelStep) > Self.wheelThrottle else { return .ignore }
            lastWheelStep = time
            return .step(delta > 0 ? 1 : -1)
        }
    }
}
