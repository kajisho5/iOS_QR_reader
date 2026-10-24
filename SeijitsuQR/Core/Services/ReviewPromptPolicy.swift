import Foundation

/// Asks for a rating once, only after more than ten successful scans, and only at a pause
/// (after a result is closed or the scan screen is left), never in the middle of a scan.
enum ReviewPromptPolicy {
    static let requiredScans = 10

    static func shouldRequest(successfulScans: Int, alreadyRequested: Bool) -> Bool {
        !alreadyRequested && successfulScans > requiredScans
    }
}
