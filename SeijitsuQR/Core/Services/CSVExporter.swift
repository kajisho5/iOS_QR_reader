import Foundation

/// Builds the history CSV: UTF-8 with BOM (so spreadsheet apps read Japanese correctly), CRLF line ends,
/// RFC 4180 quoting. Column titles and value labels are passed in so they come from the String Catalog.
struct CSVExporter: Sendable {
    struct Labels: Sendable {
        var headers: [String]
        var kindTitle: @Sendable (PayloadKind) -> String
        var symbologyTitle: @Sendable (CodeSymbology) -> String
        var sourceTitle: @Sendable (RecordSource) -> String
        var favoriteYes: String
        var favoriteNo: String
    }

    var labels: Labels
    var timeZone: TimeZone = .current

    func makeCSV(_ entries: [HistoryEntry]) -> String {
        var lines = [labels.headers.map(Self.escape).joined(separator: ",")]
        for entry in entries {
            let fields = [
                timestamp(entry.createdAt),
                labels.kindTitle(entry.kind),
                entry.content,
                entry.symbology.map(labels.symbologyTitle) ?? "",
                labels.sourceTitle(entry.source),
                entry.isFavorite ? labels.favoriteYes : labels.favoriteNo,
            ]
            lines.append(fields.map(Self.escape).joined(separator: ","))
        }
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Quotes a field when it contains a comma, quote or line break; doubles embedded quotes.
    /// A leading =, +, - or @ is prefixed with an apostrophe so spreadsheets do not run it as a formula.
    static func escape(_ field: String) -> String {
        var value = field
        if let first = value.first, "=+-@".contains(first) {
            value = "'" + value
        }
        let needsQuotes = value.contains { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }
        guard needsQuotes else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func timestamp(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(format: "%04d-%02d-%02d %02d:%02d:%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
