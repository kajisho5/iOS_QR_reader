import Foundation
import SwiftData
import Testing
@testable import SeijitsuQR

@MainActor
struct HistoryRecorderTests {
    private let container: ModelContainer
    private let recorder: HistoryRecorder

    init() throws {
        container = try HistoryContainer.make(inMemory: true)
        recorder = HistoryRecorder(context: container.mainContext)
    }

    private func draft(_ index: Int) -> RecordDraft {
        RecordDraft(content: "code-\(index)", kind: .text, symbology: .qr, source: .camera, createdAt: Date(timeIntervalSince1970: TimeInterval(index)))
    }

    private func allContents() throws -> [String] {
        try container.mainContext.fetch(FetchDescriptor<ScanRecord>(sortBy: [SortDescriptor(\.createdAt)])).map(\.content)
    }

    @Test func freePlanKeepsTheMostRecentThirty() throws {
        for i in 1...31 { try recorder.record(draft(i), isPro: false) }
        let contents = try allContents()
        #expect(contents.count == HistoryRecorder.freeLimit)
        #expect(contents.first == "code-2")
        #expect(contents.last == "code-31")
    }

    @Test func favoritesAreRemovedLast() throws {
        let first = try recorder.record(draft(1), isPro: false)
        first.isFavorite = true
        for i in 2...31 { try recorder.record(draft(i), isPro: false) }
        let contents = try allContents()
        #expect(contents.count == HistoryRecorder.freeLimit)
        #expect(contents.contains("code-1"))
        #expect(!contents.contains("code-2"))
    }

    @Test func newRecordIsKeptEvenWhenEverythingElseIsFavorite() throws {
        for i in 1...30 {
            try recorder.record(draft(i), isPro: false).isFavorite = true
        }
        try recorder.record(draft(31), isPro: false)
        let contents = try allContents()
        #expect(contents.count == HistoryRecorder.freeLimit)
        #expect(contents.contains("code-31"))
        #expect(!contents.contains("code-1"))
    }

    @Test func proHasNoLimit() throws {
        for i in 1...35 { try recorder.record(draft(i), isPro: true) }
        #expect(try allContents().count == 35)
    }

    @Test func recordStoresKindSymbologyAndSource() throws {
        let record = try recorder.record(RecordDraft(content: "https://example.com", kind: .url, symbology: .qr, source: .photo), isPro: false)
        #expect(record.kind == .url)
        #expect(record.symbology == .qr)
        #expect(record.source == .photo)
        #expect(record.isFavorite == false)
    }
}
