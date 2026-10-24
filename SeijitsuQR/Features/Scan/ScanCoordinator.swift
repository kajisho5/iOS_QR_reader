import Foundation
import Observation
import OSLog
import SwiftData
import SwiftUI

/// One code shown to the user, with the history record it was saved as (if autosave is on).
struct ScanResult: Identifiable, Equatable {
    let id = UUID()
    let code: DetectedCode
    let source: RecordSource
    let payload: ParsedPayload
    let date: Date
    var recordID: PersistentIdentifier?

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool { lhs.id == rhs.id && lhs.recordID == rhs.recordID }
}

/// Decides what happens when a code is read: de-duplication, feedback, saving, presentation.
@MainActor
@Observable
final class ScanCoordinator {
    /// Shown as a sheet on compact width.
    var presented: ScanResult? {
        didSet {
            if presented == nil, let oldValue { sheetDismissed(oldValue) }
        }
    }
    /// The most recent result; shown in the side pane on regular width.
    private(set) var latest: ScanResult?
    /// Results read during the current continuous-scan session, newest first.
    private(set) var tray: [ScanResult] = []
    private(set) var isContinuous = false
    private(set) var isToastVisible = false

    @ObservationIgnored private var seenInSession = Set<String>()
    @ObservationIgnored private var suppressedKey: String?
    @ObservationIgnored private var suppressedUntil = Date.distantPast
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored let feedback = FeedbackPlayer()
    @ObservationIgnored private var environment: Configuration?

    /// Values from the view environment, refreshed whenever they change (e.g. iPad resizing
    /// switches between sheet and pane presentation).
    struct Configuration {
        var settings: AppSettings
        var context: ModelContext
        var isPro: Bool
        /// true on compact width (results open in a sheet).
        var presentsSheet: Bool
    }

    func update(_ environment: Configuration) {
        self.environment = environment
    }
    private static let logger = Logger(subsystem: "SeijitsuQR", category: "Scan")

    func setContinuous(_ enabled: Bool) {
        isContinuous = enabled
        seenInSession.removeAll()
        tray.removeAll()
        if enabled { presented = nil }
    }

    /// Shows a result picked from the continuous-scan tray.
    func show(_ result: ScanResult) {
        latest = result
        if environment?.presentsSheet ?? true { presented = result }
    }

    /// Called when the result sheet closes, so the same code still in view is not re-opened at once.
    private func sheetDismissed(_ result: ScanResult) {
        suppressedKey = result.code.dedupeKey
        suppressedUntil = Date.now.addingTimeInterval(2)
    }

    func handle(_ code: DetectedCode, source: RecordSource) {
        guard let environment else { return }
        let presentsSheet = environment.presentsSheet
        let settings = environment.settings
        let key = code.dedupeKey
        if source == .camera {
            if isContinuous {
                // Continuous mode never records the same code twice in one session.
                guard seenInSession.insert(key).inserted else { return }
            } else {
                if presentsSheet, presented != nil { return }
                if key == suppressedKey, Date.now < suppressedUntil { return }
                if !presentsSheet, key == latest?.code.dedupeKey { return }
            }
        }

        feedback.playSuccess(sound: settings.isSoundEnabled, haptic: settings.isHapticsEnabled)
        let payload = PayloadParser.parse(code.content)
        var result = ScanResult(code: code, source: source, payload: payload, date: .now)
        if settings.isAutosaveEnabled {
            let draft = RecordDraft(content: code.content, kind: payload.kind, symbology: code.symbology, source: source, createdAt: result.date)
            do {
                result.recordID = try HistoryRecorder(context: environment.context).record(draft, isPro: environment.isPro).persistentModelID
            } catch {
                Self.logger.error("Failed to save history record: \(error.localizedDescription, privacy: .public)")
            }
        }
        latest = result
        AccessibilityNotification.Announcement(L10n.scanDetectedAnnouncement(payload.kind.title)).post()

        if isContinuous && source == .camera {
            tray.insert(result, at: 0)
            showToast()
        } else if presentsSheet {
            presented = result
        }
    }

    private func showToast() {
        isToastVisible = true
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            self?.isToastVisible = false
        }
    }
}
