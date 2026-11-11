import Foundation
@preconcurrency import LocalAuthentication
import Observation

/// Locks the history behind Face ID / Touch ID / the device passcode (docs/DESIGN_1.1.md §3.5).
/// iOS checks the face or finger on the device; the app only learns whether it succeeded.
/// Locked again whenever the app goes to the background.
@MainActor
@Observable
final class HistoryLock {
    enum Outcome: Equatable, Sendable {
        case unlocked
        case cancelled
        /// No passcode is set on the device, so the lock cannot be used.
        case unavailable
    }

    typealias Authenticate = @MainActor (_ reason: String) async -> Outcome

    private(set) var isUnlocked = false
    @ObservationIgnored private let authenticate: Authenticate

    init(authenticate: @escaping Authenticate = HistoryLock.deviceOwner) {
        self.authenticate = authenticate
    }

    @discardableResult
    func unlock() async -> Outcome {
        let outcome = await authenticate(L10n.historyLockReason)
        if outcome == .unlocked { isUnlocked = true }
        return outcome
    }

    func lock() {
        isUnlocked = false
    }

    /// The name of the device's biometry ("Face ID", "Touch ID"), or the passcode when there is none.
    static var methodName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .touchID: L10n.historyLockMethodTouchId
        case .faceID: L10n.historyLockMethodFaceId
        case .opticID: L10n.historyLockMethodOpticId
        default: L10n.historyLockMethodPasscode
        }
    }

    static func deviceOwner(_ reason: String) async -> Outcome {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return .unavailable }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) ? .unlocked : .cancelled
        } catch {
            return .cancelled
        }
    }
}
