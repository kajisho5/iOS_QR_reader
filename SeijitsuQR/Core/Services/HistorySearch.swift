import Foundation

/// A value snapshot of one history record, used for searching and exporting off the main actor.
struct HistoryEntry: Equatable, Sendable {
    var content: String
    var kind: PayloadKind
    var symbology: CodeSymbology?
    var source: RecordSource
    var createdAt: Date
    var isFavorite: Bool
}

/// Filters history by free text (content, kind name, date) plus kind and favorites.
struct HistoryQuery: Equatable, Sendable {
    var text = ""
    var kind: PayloadKind?
    var favoritesOnly = false

    var isFiltering: Bool { !normalizedText.isEmpty || kind != nil || favoritesOnly }

    var normalizedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// - Parameters:
    ///   - kindTitle: localized name of the entry's kind, so "連絡先" finds contacts.
    ///   - dateTexts: the date written the ways people type it (e.g. "2026/10/24 8:12", "10月24日").
    func matches(_ entry: HistoryEntry, kindTitle: String, dateTexts: [String]) -> Bool {
        if favoritesOnly && !entry.isFavorite { return false }
        if let kind, entry.kind != kind { return false }
        let needle = normalizedText
        guard !needle.isEmpty else { return true }
        let haystacks = [entry.content, kindTitle] + dateTexts
        return haystacks.contains { $0.localizedStandardContains(needle) }
    }
}

enum HistoryDateText {
    /// Every textual form of a date that search should match.
    static func searchable(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> [String] {
        var numeric = Date.FormatStyle(date: .numeric, time: .shortened)
        numeric.calendar = calendar
        numeric.timeZone = calendar.timeZone
        numeric.locale = locale
        var long = Date.FormatStyle(date: .long, time: .omitted)
        long.calendar = calendar
        long.timeZone = calendar.timeZone
        long.locale = locale
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let y = parts.year ?? 0, m = parts.month ?? 0, d = parts.day ?? 0
        return [
            date.formatted(numeric),
            date.formatted(long),
            String(format: "%04d/%02d/%02d", y, m, d),
            String(format: "%04d-%02d-%02d", y, m, d),
            String(format: "%d/%d", m, d),
        ]
    }
}
