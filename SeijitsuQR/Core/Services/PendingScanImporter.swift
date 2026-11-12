import Foundation
import OSLog
import SwiftData

/// Adds what the share extension read to the history (docs/DESIGN_1.1.md §5, E). Run when the app becomes active.
/// When automatic saving is off, the queue is emptied without saving, as the extension says it would be.
@MainActor
enum PendingScanImporter {
    private static let logger = Logger(subsystem: "SeijitsuQR", category: "Share")

    @discardableResult
    static func importAll(context: ModelContext, isPro: Bool, autosave: Bool, from store: WidgetSnapshot.Store = .keychain) -> Int {
        let pending = PendingScans.takeAll(from: store)
        guard autosave, !pending.isEmpty else { return 0 }
        let recorder = HistoryRecorder(context: context)
        var count = 0
        for scan in pending {
            let draft = RecordDraft(content: scan.content, kind: PayloadParser.parse(scan.content).kind,
                                    symbology: CodeSymbology(rawValue: scan.symbologyRaw), source: .share, createdAt: scan.date)
            do {
                _ = try recorder.record(draft, isPro: isPro)
                count += 1
            } catch {
                logger.error("Failed to add a shared scan: \(error.localizedDescription, privacy: .public)")
            }
        }
        return count
    }
}
