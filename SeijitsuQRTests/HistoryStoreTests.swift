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
}
