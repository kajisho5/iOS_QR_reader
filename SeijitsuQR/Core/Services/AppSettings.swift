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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.sound: true, Key.haptics: true, Key.autosave: true])
        isSoundEnabled = defaults.bool(forKey: Key.sound)
        isHapticsEnabled = defaults.bool(forKey: Key.haptics)
        isAutosaveEnabled = defaults.bool(forKey: Key.autosave)
    }
}
