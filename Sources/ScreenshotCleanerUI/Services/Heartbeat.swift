import AppKit

/// Fires roughly hourly and on wake from sleep, so screenshots can age into range and auto-clean can catch up.
final class Heartbeat {
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    init(interval: TimeInterval = 3600, onBeat: @escaping @MainActor @Sendable () -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in onBeat() }
        }
        timer?.tolerance = interval / 6 // let macOS coalesce wakeups
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in onBeat() }
        }
    }

    deinit {
        timer?.invalidate()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
