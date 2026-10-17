import AppKit
import CleanerCore

/// SwiftUI has no scroll-wheel hook on macOS 14, so this watches the app's scroll events directly.
/// The handler returns true to consume an event, false to let it through.
final class ScrollWheelMonitor {
    private var token: Any?

    init(handler: @escaping (ScrollInput) -> Bool) {
        token = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard let input = ScrollInput(event) else { return event }
            return handler(input) ? nil : event
        }
    }

    deinit {
        if let token { NSEvent.removeMonitor(token) }
    }
}

extension ScrollInput {
    /// Reduces an `NSEvent` to deck input. Dominant axis wins; positive means "toward the next card".
    init?(_ event: NSEvent, now: Date = Date()) {
        let dx = event.scrollingDeltaX, dy = event.scrollingDeltaY
        let delta = Double(abs(dx) > abs(dy) ? -dx : -dy)
        guard event.hasPreciseScrollingDeltas else {
            self = .wheel(delta: delta, at: now)
            return
        }
        if event.momentumPhase != [] {
            self = .momentum
            return
        }
        switch event.phase {
        case .began: self = .began
        case .changed: self = .changed(delta: delta)
        case .ended, .cancelled: self = .ended
        default: return nil
        }
    }
}
