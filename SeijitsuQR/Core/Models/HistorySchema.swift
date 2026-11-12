import Foundation
import SwiftData

/// Version 1 of the on-disk history schema. Future changes add a new `VersionedSchema`
/// and a migration stage in `HistoryMigrationPlan` so updates never drop existing records.
enum HistorySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [ScanRecord.self] }

    @Model
    final class ScanRecord {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        /// The exact string read from (or encoded into) the code.
        var content: String
        var kindRaw: String
        var symbologyRaw: String?
        var sourceRaw: String
        var isFavorite: Bool

        init(
            id: UUID = UUID(),
            createdAt: Date,
            content: String,
            kind: PayloadKind,
            symbology: CodeSymbology?,
            source: RecordSource,
            isFavorite: Bool = false
        ) {
            self.id = id
            self.createdAt = createdAt
            self.content = content
            self.kindRaw = kind.rawValue
            self.symbologyRaw = symbology?.rawValue
            self.sourceRaw = source.rawValue
            self.isFavorite = isFavorite
        }
    }
}

/// Version 2 (1.2): adds a free-text note (docs/DESIGN_1.2.md §3, H). Migrated from V1 automatically
/// (a lightweight stage: the new attribute is optional, so existing records keep everything and get no note).
enum HistorySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [ScanRecord.self] }

    @Model
    final class ScanRecord {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        /// The exact string read from (or encoded into) the code.
        var content: String
        var kindRaw: String
        var symbologyRaw: String?
        var sourceRaw: String
        var isFavorite: Bool
        /// The user's own note (at most `ScanRecord.noteLimit` characters); nil when there is none.
        var note: String?

        init(
            id: UUID = UUID(),
            createdAt: Date,
            content: String,
            kind: PayloadKind,
            symbology: CodeSymbology?,
            source: RecordSource,
            isFavorite: Bool = false,
            note: String? = nil
        ) {
            self.id = id
            self.createdAt = createdAt
            self.content = content
            self.kindRaw = kind.rawValue
            self.symbologyRaw = symbology?.rawValue
            self.sourceRaw = source.rawValue
            self.isFavorite = isFavorite
            self.note = note
        }
    }
}

typealias ScanRecord = HistorySchemaV2.ScanRecord

extension ScanRecord {
    static let noteLimit = 200

    var kind: PayloadKind { PayloadKind(rawValue: kindRaw) ?? .text }

    /// The note with surrounding whitespace removed; nil when empty.
    var trimmedNote: String? {
        let text = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }
    var symbology: CodeSymbology? { symbologyRaw.flatMap(CodeSymbology.init(rawValue:)) }
    var source: RecordSource { RecordSource(rawValue: sourceRaw) ?? .camera }
}

enum HistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [HistorySchemaV1.self, HistorySchemaV2.self] }
    static var stages: [MigrationStage] { [.lightweight(fromVersion: HistorySchemaV1.self, toVersion: HistorySchemaV2.self)] }
}

enum HistoryContainer {
    /// Application Support is included in iCloud Backup and device-to-device transfer;
    /// the store is never excluded from backup and never placed in Caches or tmp.
    static func storeURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return directory.appending(path: "History.store")
    }

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory {
            let schema = Schema(versionedSchema: HistorySchemaV2.self)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: HistoryMigrationPlan.self, configurations: [configuration])
        }
        return try make(at: storeURL())
    }

    /// Opens (or creates) the on-disk store at `url`. The app always uses `storeURL()`;
    /// tests pass a temporary location.
    static func make(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HistorySchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: HistoryMigrationPlan.self, configurations: [configuration])
    }
}
