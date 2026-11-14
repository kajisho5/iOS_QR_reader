import Foundation
import Observation

/// User preferences, persisted in the app's own UserDefaults (required-reason API: CA92.1).
@MainActor
@Observable
final class AppSettings {
    enum Key {
        static let sound = "settings.sound"
        static let haptics = "settings.haptics"
        static let autosave = "settings.autosave"
        static let searchEngine = "settings.searchEngine"
        static let historyLock = "settings.historyLock"
        static let watchEnabled = "settings.watch"
        static let watchCodeIDs = "settings.watch.codes"
        static let successfulScans = "usage.successfulScans"
        static let reviewRequested = "usage.reviewRequested"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isSoundEnabled: Bool {
        didSet { defaults.set(isSoundEnabled, forKey: Key.sound) }
    }

    var isHapticsEnabled: Bool {
        didSet { defaults.set(isHapticsEnabled, forKey: Key.haptics) }
    }

    var isAutosaveEnabled: Bool {
        didSet { defaults.set(isAutosaveEnabled, forKey: Key.autosave) }
    }

    /// Ask for Face ID / Touch ID / the passcode before showing the history.
    var isHistoryLockEnabled: Bool {
        didSet { defaults.set(isHistoryLockEnabled, forKey: Key.historyLock) }
    }

    /// Show the chosen favorites on Apple Watch (Pro).
    var isWatchEnabled: Bool {
        didSet { defaults.set(isWatchEnabled, forKey: Key.watchEnabled) }
    }

    /// The favorites (record ids) sent to Apple Watch.
    var watchCodeIDs: Set<String> {
        didSet { defaults.set(Array(watchCodeIDs).sorted(), forKey: Key.watchCodeIDs) }
    }

    /// Where product codes are searched (only when the user taps "ウェブで検索").
    var searchEngine: SearchEngine {
        didSet { defaults.set(searchEngine.rawValue, forKey: Key.searchEngine) }
    }

    /// Counted only to decide when to ask for a rating; never leaves the device.
    var successfulScans: Int {
        didSet { defaults.set(successfulScans, forKey: Key.successfulScans) }
    }

    var hasRequestedReview: Bool {
        didSet { defaults.set(hasRequestedReview, forKey: Key.reviewRequested) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.sound: true, Key.haptics: true, Key.autosave: true])
        isSoundEnabled = defaults.bool(forKey: Key.sound)
        isHapticsEnabled = defaults.bool(forKey: Key.haptics)
        isAutosaveEnabled = defaults.bool(forKey: Key.autosave)
        isHistoryLockEnabled = defaults.bool(forKey: Key.historyLock)
        isWatchEnabled = defaults.bool(forKey: Key.watchEnabled)
        watchCodeIDs = Set(defaults.stringArray(forKey: Key.watchCodeIDs) ?? [])
        searchEngine = defaults.string(forKey: Key.searchEngine).flatMap(SearchEngine.init(rawValue:)) ?? .google
        successfulScans = defaults.integer(forKey: Key.successfulScans)
        hasRequestedReview = defaults.bool(forKey: Key.reviewRequested)
    }
}
