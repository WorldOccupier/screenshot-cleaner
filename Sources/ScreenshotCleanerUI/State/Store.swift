import CleanerCore
import Foundation
import Observation

/// App state: the screenshots found, the user's settings, and the clean actions.
/// Dependencies are injected so the store can be driven against a temp folder in tests.
@MainActor @Observable
public final class Store {
    /// Every screenshot in the folder, oldest first. `items` is the subset old enough to clean.
    public private(set) var all: [Screenshot] = []
    public private(set) var isWorking = false
    public private(set) var lastCleaned: Cleaner.Result?
    public let folder: URL

    /// 0 means "any age".
    public var ageDays: Int {
        didSet { preferences.ageDays = ageDays; lastCleaned = nil }
    }
    public var autoClean: Bool {
        didSet { preferences.autoClean = autoClean }
    }
    /// Also clean screen recordings (.mov), not just still screenshots.
    public var includeRecordings: Bool {
        didSet { preferences.includeRecordings = includeRecordings; lastCleaned = nil; rescan() }
    }

    public var items: [Screenshot] { all.olderThan(days: ageDays, now: now()) }
    public var summary: CleanSummary {
        CleanSummary(cleanable: items, totalCount: all.count, lastCleaned: lastCleaned)
    }

    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let remove: Cleaner.Remover
    @ObservationIgnored private var scanGeneration = 0
    @ObservationIgnored private var watcher: FolderWatcher?
    @ObservationIgnored private var heartbeat: Heartbeat?

    /// The live app store: watches the screenshot folder and runs the hourly heartbeat.
    public convenience init() {
        self.init(folder: ScreenshotScanner.defaultLocation())
        startMonitoring()
    }

    init(
        folder: URL,
        preferences: Preferences = Preferences(),
        now: @escaping () -> Date = Date.init,
        remove: @escaping Cleaner.Remover = Cleaner.moveToTrash
    ) {
        self.folder = folder
        self.preferences = preferences
        self.now = now
        self.remove = remove
        ageDays = preferences.ageDays
        autoClean = preferences.autoClean
        includeRecordings = preferences.includeRecordings
    }

    private func startMonitoring() {
        Log.store.info("Starting with \(self.folder.path, privacy: .private)")
        watcher = FolderWatcher(url: folder) { [weak self] in
            MainActor.assumeIsolated { self?.rescan() }
        }
        heartbeat = Heartbeat { [weak self] in
            Task { await self?.heartbeatTick() }
        }
        Task { await heartbeatTick() }
    }

    public func rescan() { Task { await refresh() } }

    /// Rescans the folder off the main thread. A newer scan supersedes any still in flight.
    func refresh() async {
        scanGeneration += 1
        let generation = scanGeneration
        let folder = folder
        let includeRecordings = includeRecordings
        let found = await Task.detached(priority: .utility) {
            ScreenshotScanner.scan(folder: folder, includeRecordings: includeRecordings)
        }.value
        guard generation == scanGeneration else { return }
        Log.store.debug("Scan found \(found.count, privacy: .public) screenshots in \(self.folder.path, privacy: .private)")
        if found != all { all = found }
    }

    /// Refreshes the count, then runs auto-clean if it's on and a day has passed since it last ran.
    func heartbeatTick() async {
        await refresh()
        await autoCleanIfDue()
    }

    func autoCleanIfDue() async {
        guard autoClean, AutoCleanPolicy.isDue(lastRun: preferences.lastAutoClean, now: now()) else { return }
        // Record the run even when there's nothing to clean, so it stays once a day.
        preferences.lastAutoClean = now()
        let batch = all.olderThan(days: AutoCleanPolicy.ageDays(forSelection: ageDays), now: now())
        Log.store.info("Auto-clean is due: \(batch.count, privacy: .public) screenshots to move")
        await clean(batch)
    }

    public func clean() async { await clean(items) }

    private func clean(_ batch: [Screenshot]) async {
        guard !isWorking, !batch.isEmpty else { return }
        isWorking = true
        Log.store.info("Moving \(batch.count, privacy: .public) screenshots to the Trash")
        let remove = remove
        let result = await Task.detached(priority: .userInitiated) { Cleaner.trash(batch, using: remove) }.value
        lastCleaned = result
        isWorking = false
        Log.store.info("Moved \(result.count, privacy: .public) screenshots (\(result.bytes, privacy: .public) bytes)")
        await refresh()
    }
}
