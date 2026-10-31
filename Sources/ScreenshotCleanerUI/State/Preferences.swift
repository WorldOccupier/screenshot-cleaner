import CleanerCore
import Foundation

/// Persisted user settings. Backed by `UserDefaults` so tests can use an isolated suite.
struct Preferences {
    enum Key {
        static let ageDays = "ageDays"
        static let autoClean = "autoClean"
        static let includeRecordings = "includeRecordings"
        static let lastAutoClean = "lastAutoClean"
    }

    static let defaultAgeDays = AgeOption.default

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var ageDays: Int {
        get { defaults.object(forKey: Key.ageDays) as? Int ?? Self.defaultAgeDays }
        nonmutating set { defaults.set(newValue, forKey: Key.ageDays) }
    }

    var autoClean: Bool {
        get { defaults.bool(forKey: Key.autoClean) }
        nonmutating set { defaults.set(newValue, forKey: Key.autoClean) }
    }

    var includeRecordings: Bool {
        get { defaults.bool(forKey: Key.includeRecordings) }
        nonmutating set { defaults.set(newValue, forKey: Key.includeRecordings) }
    }

    var lastAutoClean: Date? {
        get { defaults.object(forKey: Key.lastAutoClean) as? Date }
        nonmutating set { defaults.set(newValue, forKey: Key.lastAutoClean) }
    }
}
