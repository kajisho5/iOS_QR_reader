import Foundation
import SwiftData

/// What to store for one scanned or created code.
struct RecordDraft: Sendable {
    var content: String
    var kind: PayloadKind
    var symbology: CodeSymbology?
    var source: RecordSource
    var createdAt: Date = .now
}

/// Writes history records and enforces the free-plan limit.
@MainActor
struct HistoryRecorder {
    /// The free plan keeps the most recent records only (Pro removes the limit).
    static let freeLimit = 30

    let context: ModelContext

    @discardableResult
    func record(_ draft: RecordDraft, isPro: Bool) throws -> ScanRecord {
        let record = ScanRecord(
            createdAt: draft.createdAt,
            content: draft.content,
            kind: draft.kind,
            symbology: draft.symbology,
            source: draft.source
        )
        context.insert(record)
        if !isPro {
            try trimToFreeLimit(keeping: record)
        }
        try context.save()
        return record
    }

    /// Deletes the oldest records beyond the free limit. Non-favorites go first; favorites are
    /// removed only when everything else is gone. The record just added is always kept.
    func trimToFreeLimit(keeping kept: ScanRecord? = nil) throws {
        let all = try context.fetch(FetchDescriptor<ScanRecord>(sortBy: [SortDescriptor(\.createdAt, order: .forward)]))
        let excess = all.count - Self.freeLimit
        guard excess > 0 else { return }
        let candidates = all.filter { $0 !== kept }
        let ordered = candidates.filter { !$0.isFavorite } + candidates.filter(\.isFavorite)
        for record in ordered.prefix(excess) {
            context.delete(record)
        }
    }
}
