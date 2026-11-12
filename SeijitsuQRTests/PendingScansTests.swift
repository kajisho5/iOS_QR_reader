import Foundation
import SwiftData
import Testing
@testable import SeijitsuQR

/// Codes read in the share sheet reach the history the next time the app opens (docs/DESIGN_1.1.md §5, E).
@MainActor
struct PendingScansTests {
    private func temporaryStore() -> (WidgetSnapshot.Store, URL) {
        let url = FileManager.default.temporaryDirectory.appending(path: "pending-\(UUID().uuidString).json")
        return (.file(url), url)
    }

    @Test func queueKeepsOrderDropsDuplicatesAndEmptiesWhenTaken() throws {
        let (store, url) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        try PendingScans.append(PendingScan(content: "A", symbologyRaw: "qr", date: .now), to: store)
        try PendingScans.append(PendingScan(content: "B", symbologyRaw: "qr", date: .now), to: store)
        try PendingScans.append(PendingScan(content: "A", symbologyRaw: "qr", date: .now), to: store)
        #expect(PendingScans.takeAll(from: store).map(\.content) == ["B", "A"])
        #expect(PendingScans.takeAll(from: store).isEmpty)
    }

    @Test func queueKeepsOnlyTheNewest() throws {
        let (store, url) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        for i in 0..<(PendingScans.limit + 5) {
            try PendingScans.append(PendingScan(content: "\(i)", symbologyRaw: "qr", date: .now), to: store)
        }
        let queue = PendingScans.load(from: store)
        #expect(queue.count == PendingScans.limit)
        #expect(queue.first?.content == "5")
    }

    @Test func importAddsToHistoryAsShared() throws {
        let (store, url) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        try PendingScans.append(PendingScan(content: "https://example.com", symbologyRaw: "qr", date: Date(timeIntervalSince1970: 1_793_000_000)), to: store)
        let container = try HistoryContainer.make(inMemory: true)

        #expect(PendingScanImporter.importAll(context: container.mainContext, isPro: false, autosave: true, from: store) == 1)

        let records = try container.mainContext.fetch(FetchDescriptor<ScanRecord>())
        #expect(records.count == 1)
        #expect(records.first?.source == .share)
        #expect(records.first?.kind == .url)
        #expect(records.first?.createdAt == Date(timeIntervalSince1970: 1_793_000_000))
        #expect(PendingScans.load(from: store).isEmpty)
    }

    @Test func importWithAutosaveOffDiscardsTheQueue() throws {
        let (store, url) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        try PendingScans.append(PendingScan(content: "x", symbologyRaw: "qr", date: .now), to: store)
        let container = try HistoryContainer.make(inMemory: true)

        #expect(PendingScanImporter.importAll(context: container.mainContext, isPro: false, autosave: false, from: store) == 0)

        #expect(try container.mainContext.fetch(FetchDescriptor<ScanRecord>()).isEmpty)
        #expect(PendingScans.load(from: store).isEmpty)
    }
}
