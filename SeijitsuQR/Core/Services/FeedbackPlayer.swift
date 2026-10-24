import AudioToolbox
import UIKit

/// Plays the scan-success sound and haptic, each only when enabled in settings.
/// The sound is a short tone bundled with the app; system sounds obey the silent switch.
@MainActor
final class FeedbackPlayer {
    private var soundID: SystemSoundID = 0
    private let haptics = UINotificationFeedbackGenerator()

    init() {
        if let url = Bundle.main.url(forResource: "scan_beep", withExtension: "wav") {
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        }
    }

    func prepare() {
        haptics.prepare()
    }

    func playSuccess(sound: Bool, haptic: Bool) {
        if haptic {
            haptics.notificationOccurred(.success)
        }
        if sound, soundID != 0 {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}
