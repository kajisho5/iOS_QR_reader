import Foundation
import OSLog
import SwiftData
import WidgetKit

/// Writes the favorites (and the Pro state) for the home screen widget, and asks WidgetKit to redraw only when
/// something changed. Called at launch, when Pro changes, and when the app leaves the screen.
@MainActor
enum WidgetSnapshotWriter {
    private static let logger = Logger(subsystem: "SeijitsuQR", category: "Widget")

    static func update(context: ModelContext, isPro: Bool, to url: URL? = WidgetSnapshot.fileURL) {
        let descriptor = FetchDescriptor<ScanRecord>(predicate: #Predicate<ScanRecord> { $0.isFavorite }, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let records = (try? context.fetch(descriptor)) ?? []
        let snapshot = WidgetSnapshot(isPro: isPro, favorites: records.map(favorite))
        guard WidgetSnapshot.load(from: url) != snapshot else { return }
        do {
            try snapshot.save(to: url)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.error("Failed to write the widget snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func favorite(_ record: ScanRecord) -> WidgetSnapshot.Favorite {
        WidgetSnapshot.Favorite(id: record.id, title: title(for: record), kindTitle: record.kind.title,
                                symbologyRaw: record.symbologyRaw, content: record.content)
    }

    /// The note if there is one, else the network name, the domain, or the first line of the content.
    static func title(for record: ScanRecord) -> String {
        if let note = record.trimmedNote { return String(note.prefix(40)) }
        switch PayloadParser.parse(record.content) {
        case .wifi(let network): return network.ssid
        case .url(let url): return url.host ?? record.content
        case .contact(let card): return card.formattedName ?? card.organization ?? record.kind.title
        default:
            let line = record.content.split(whereSeparator: \.isNewline).first.map(String.init) ?? record.content
            return String(line.trimmingCharacters(in: .whitespaces).prefix(40))
        }
    }
}
