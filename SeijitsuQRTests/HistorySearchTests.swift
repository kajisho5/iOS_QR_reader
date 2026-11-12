import Foundation
import Testing
@testable import SeijitsuQR

struct HistorySearchTests {
    private let date = Date(timeIntervalSince1970: 1_793_000_000) // 2026-10-26 (UTC)
    private var tokyo: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func entry(_ content: String, _ kind: PayloadKind = .text, favorite: Bool = false) -> HistoryEntry {
        HistoryEntry(content: content, kind: kind, symbology: .qr, source: .camera, createdAt: date, isFavorite: favorite)
    }

    private func dates() -> [String] { HistoryDateText.searchable(date, calendar: tokyo, locale: Locale(identifier: "ja_JP")) }

    @Test func emptyQueryMatchesEverything() {
        #expect(HistoryQuery().matches(entry("abc"), kindTitle: "テキスト", dateTexts: dates()))
        #expect(!HistoryQuery().isFiltering)
    }

    @Test func textMatchesContentCaseInsensitively() {
        let query = HistoryQuery(text: "EXAMPLE")
        #expect(query.matches(entry("https://example.com", .url), kindTitle: "URL", dateTexts: dates()))
        #expect(!query.matches(entry("other"), kindTitle: "テキスト", dateTexts: dates()))
    }

    @Test func textMatchesKindName() {
        #expect(HistoryQuery(text: "連絡先").matches(entry("BEGIN:VCARD", .contact), kindTitle: "連絡先", dateTexts: dates()))
    }

    @Test func textMatchesDate() {
        let texts = dates()
        #expect(HistoryQuery(text: "2026/10/26").matches(entry("x"), kindTitle: "テキスト", dateTexts: texts))
        #expect(HistoryQuery(text: "10/26").matches(entry("x"), kindTitle: "テキスト", dateTexts: texts))
        #expect(!HistoryQuery(text: "2026/10/27").matches(entry("x"), kindTitle: "テキスト", dateTexts: texts))
    }

    @Test func kindAndFavoriteFilters() {
        let favoriteURL = entry("https://a", .url, favorite: true)
        let plainURL = entry("https://b", .url)
        #expect(HistoryQuery(kind: .url).matches(plainURL, kindTitle: "URL", dateTexts: []))
        #expect(!HistoryQuery(kind: .wifi).matches(plainURL, kindTitle: "URL", dateTexts: []))
        #expect(HistoryQuery(favoritesOnly: true).matches(favoriteURL, kindTitle: "URL", dateTexts: []))
        #expect(!HistoryQuery(favoritesOnly: true).matches(plainURL, kindTitle: "URL", dateTexts: []))
    }
}

struct CSVExporterTests {
    private let exporter = CSVExporter(
        labels: .init(
            headers: ["日時", "種類", "内容", "コード形式", "取得元", "お気に入り", "メモ"],
            kindTitle: { $0.rawValue },
            symbologyTitle: { $0.rawValue },
            sourceTitle: { $0.rawValue },
            favoriteYes: "はい",
            favoriteNo: "いいえ"
        ),
        timeZone: TimeZone(identifier: "Asia/Tokyo")!
    )

    @Test func startsWithBOMAndHeader() {
        let csv = exporter.makeCSV([])
        #expect(csv.hasPrefix("\u{FEFF}日時,種類,内容,コード形式,取得元,お気に入り,メモ\r\n"))
    }

    @Test func rowUsesLocalTimeAndLabels() {
        let entry = HistoryEntry(content: "4901234567894", kind: .text, symbology: .ean13, source: .camera, createdAt: Date(timeIntervalSince1970: 0), isFavorite: true)
        let lines = exporter.makeCSV([entry]).split(separator: "\r\n")
        #expect(lines[1] == "1970-01-01 09:00:00,text,4901234567894,ean13,camera,はい,")
        let noted = HistoryEntry(content: "x", kind: .text, symbology: nil, source: .paste, createdAt: Date(timeIntervalSince1970: 0), isFavorite: false, note: "倉庫B, 棚3")
        #expect(exporter.makeCSV([noted]).split(separator: "\r\n")[1] == "1970-01-01 09:00:00,text,x,,paste,いいえ,\"倉庫B, 棚3\"")
    }

    @Test func quotesCommasQuotesAndNewlines() {
        #expect(CSVExporter.escape("a,b") == "\"a,b\"")
        #expect(CSVExporter.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSVExporter.escape("line1\nline2") == "\"line1\nline2\"")
        #expect(CSVExporter.escape("plain") == "plain")
    }

    @Test func neutralizesSpreadsheetFormulas() {
        #expect(CSVExporter.escape("=HYPERLINK(\"x\")") == "\"'=HYPERLINK(\"\"x\"\")\"")
        #expect(CSVExporter.escape("+81-3") == "'+81-3")
    }
}

/// Notes are searchable (docs/DESIGN_1.2.md §3, H).
struct HistoryNoteSearchTests {
    @Test func textMatchesTheNote() {
        let entry = HistoryEntry(content: "WIFI:S:Guest;;", kind: .wifi, symbology: .qr, source: .camera, createdAt: .now, isFavorite: false, note: "3階 大会議室の来客用")
        #expect(HistoryQuery(text: "会議室").matches(entry, kindTitle: "Wi-Fi", dateTexts: []))
        #expect(!HistoryQuery(text: "倉庫").matches(entry, kindTitle: "Wi-Fi", dateTexts: []))
    }
}
