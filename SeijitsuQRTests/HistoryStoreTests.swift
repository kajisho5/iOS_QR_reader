import Foundation
import SwiftData
import Testing
@testable import SeijitsuQR

/// The history must survive relaunches and app updates, and live where iCloud Backup and
/// device-to-device transfer include it.
@MainActor
struct HistoryStoreTests {
    @Test func storeLivesInApplicationSupportAndIsBackedUp() throws {
        let url = try HistoryContainer.storeURL()
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        #expect(url.deletingLastPathComponent().standardizedFileURL == applicationSupport.standardizedFileURL)
        #expect(url.lastPathComponent == "History.store")
        let values = try applicationSupport.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup != true)
    }

    @Test func recordsSurviveReopeningTheStore() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "History.store")

        do {
            let container = try HistoryContainer.make(at: url)
            let draft = RecordDraft(content: "https://example.com", kind: .url, symbology: .qr, source: .camera, createdAt: .now)
            let record = try HistoryRecorder(context: container.mainContext).record(draft, isPro: false)
            record.isFavorite = true
            try container.mainContext.save()
        }

        let reopened = try HistoryContainer.make(at: url)
        let records = try reopened.mainContext.fetch(FetchDescriptor<ScanRecord>())
        #expect(records.count == 1)
        #expect(records.first?.content == "https://example.com")
        #expect(records.first?.kind == .url)
        #expect(records.first?.isFavorite == true)
    }

    /// A store written by 1.0–1.1 (schema V1) opens in 1.2 (V2) with every record kept and no note.
    @Test func version1StoreMigratesToVersion2() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "History.store")
        let id = UUID()

        do {
            let schema = Schema(versionedSchema: HistorySchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            container.mainContext.insert(HistorySchemaV1.ScanRecord(
                id: id, createdAt: Date(timeIntervalSince1970: 1_793_000_000), content: "https://example.com",
                kind: .url, symbology: .qr, source: .camera, isFavorite: true
            ))
            try container.mainContext.save()
        }

        do {
            let migrated = try HistoryContainer.make(at: url)
            let records = try migrated.mainContext.fetch(FetchDescriptor<ScanRecord>())
            #expect(records.count == 1)
            let record = try #require(records.first)
            #expect(record.id == id)
            #expect(record.content == "https://example.com")
            #expect(record.kind == .url)
            #expect(record.isFavorite)
            #expect(record.createdAt == Date(timeIntervalSince1970: 1_793_000_000))
            #expect(record.note == nil)
            record.note = "倉庫Bの棚3"
            try migrated.mainContext.save()
        }

        let reopened = try HistoryContainer.make(at: url)
        #expect(try reopened.mainContext.fetch(FetchDescriptor<ScanRecord>()).first?.note == "倉庫Bの棚3")
    }
}
