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
        successfulScans = defaults.integer(forKey: Key.successfulScans)
        hasRequestedReview = defaults.bool(forKey: Key.reviewRequested)
    }
}
