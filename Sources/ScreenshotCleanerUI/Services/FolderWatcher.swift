import Foundation

/// Calls `onChange` (on the main queue) when a folder's entries change.
/// Uses a kernel vnode notification, not polling, and debounces bursts of writes into one call.
final class FolderWatcher {
    private let source: DispatchSourceFileSystemObject
    private var pending: DispatchWorkItem?

    init?(url: URL, debounce: TimeInterval = 0.4, onChange: @escaping () -> Void) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .rename, .delete], queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            pending?.cancel()
            let work = DispatchWorkItem(block: onChange)
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
        }
        source.setCancelHandler { close(fd) }
        source.resume()
    }

    deinit {
        pending?.cancel()
        source.cancel()
    }
}
