import Foundation
import SwiftData
import Testing
@testable import SeijitsuQR

/// The widget's data (docs/DESIGN_1.1.md §4, B): only favorites, with a readable title, written as JSON.
@MainActor
struct WidgetSnapshotTests {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "widget-\(UUID().uuidString).json")
    }

    @Test func writesOnlyFavoritesNewestFirst() throws {
        let container = try HistoryContainer.make(inMemory: true)
        let recorder = HistoryRecorder(context: container.mainContext)
        let wifi = try recorder.record(RecordDraft(content: "WIFI:T:WPA;S:Guest;P:secret;;", kind: .wifi, symbology: .qr, source: .camera, createdAt: .now.addingTimeInterval(-60)), isPro: true)
        let url = try recorder.record(RecordDraft(content: "https://www.example.co.jp/menu", kind: .url, symbology: .qr, source: .camera, createdAt: .now), isPro: true)
        _ = try recorder.record(RecordDraft(content: "not a favorite", kind: .text, symbology: .qr, source: .camera), isPro: true)
        wifi.isFavorite = true
        url.isFavorite = true
        let file = temporaryURL()
        defer { try? FileManager.default.removeItem(at: file) }

        WidgetSnapshotWriter.update(context: container.mainContext, isPro: true, to: file)

        let snapshot = try #require(WidgetSnapshot.load(from: file))
        #expect(snapshot.isPro)
        #expect(snapshot.favorites.map(\.title) == ["www.example.co.jp", "Guest"])
        #expect(snapshot.favorites.last?.content == "WIFI:T:WPA;S:Guest;P:secret;;")
    }

    @Test func noteIsUsedAsTheTitle() throws {
        let container = try HistoryContainer.make(inMemory: true)
        let record = try HistoryRecorder(context: container.mainContext).record(RecordDraft(content: "4901234567894", kind: .text, symbology: .ean13, source: .camera), isPro: true)
        record.note = "  倉庫Bの棚3  "
        #expect(WidgetSnapshotWriter.title(for: record) == "倉庫Bの棚3")
    }

    @Test func roundTripsThroughJSON() throws {
        let file = temporaryURL()
        defer { try? FileManager.default.removeItem(at: file) }
        let snapshot = WidgetSnapshot(isPro: false, favorites: [.init(id: UUID(), title: "会員証", kindTitle: "テキスト", symbologyRaw: nil, content: "No.0012")])
        try snapshot.save(to: file)
        #expect(WidgetSnapshot.load(from: file) == snapshot)
    }
}
