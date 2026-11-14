import Foundation
import OSLog
import SwiftData
import WatchConnectivity

/// Sends the chosen favorites to the paired Apple Watch (docs/DESIGN_1.2.md §8, K, Pro). The codes are drawn
/// here, because the watch has no Core Image. WatchConnectivity carries them between the paired devices only.
@MainActor
@Observable
final class WatchLink: NSObject, WCSessionDelegate {
    static let shared = WatchLink()

    /// A watch is paired and our watch app is installed on it.
    private(set) var isAvailable = false
    @ObservationIgnored private let logger = Logger(subsystem: "SeijitsuQR", category: "Watch")

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends the favorites chosen in Settings, or an empty list when the feature is off or Pro is not unlocked.
    func update(context: ModelContext, settings: AppSettings, isPro: Bool) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        var codes: [WatchCode] = []
        if isPro && settings.isWatchEnabled {
            let ids = settings.watchCodeIDs
            let descriptor = FetchDescriptor<ScanRecord>(predicate: #Predicate<ScanRecord> { $0.isFavorite },
                                                         sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let records = ((try? context.fetch(descriptor)) ?? []).filter { ids.contains($0.id.uuidString) }
            codes = records.compactMap(Self.code)
        }
        do {
            try WCSession.default.updateApplicationContext([WatchCodes.contextKey: try WatchCodes.encode(codes)])
        } catch {
            logger.error("Failed to send codes to the watch: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func code(_ record: ScanRecord) -> WatchCode? {
        let symbology = record.symbology ?? .qr
        guard let image = CodeImageRenderer.image(for: record.content, symbology: symbology, targetWidth: 360),
              let png = image.pngData() else { return nil }
        return WatchCode(id: record.id, title: WidgetSnapshotWriter.title(for: record), kindTitle: record.kind.title, image: png)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let available = activationState == .activated && session.isPaired && session.isWatchAppInstalled
        Task { @MainActor in self.isAvailable = available }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let available = session.isPaired && session.isWatchAppInstalled
        Task { @MainActor in self.isAvailable = available }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Switching to another watch: activate again for the new one.
        session.activate()
    }
}
