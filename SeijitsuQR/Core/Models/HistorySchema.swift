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

typealias ScanRecord = HistorySchemaV1.ScanRecord

extension ScanRecord {
    var kind: PayloadKind { PayloadKind(rawValue: kindRaw) ?? .text }
    var symbology: CodeSymbology? { symbologyRaw.flatMap(CodeSymbology.init(rawValue:)) }
    var source: RecordSource { RecordSource(rawValue: sourceRaw) ?? .camera }
}

enum HistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [HistorySchemaV1.self] }
    static var stages: [MigrationStage] { [] }
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
            let schema = Schema(versionedSchema: HistorySchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: HistoryMigrationPlan.self, configurations: [configuration])
        }
        return try make(at: storeURL())
    }

    /// Opens (or creates) the on-disk store at `url`. The app always uses `storeURL()`;
    /// tests pass a temporary location.
    static func make(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HistorySchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: HistoryMigrationPlan.self, configurations: [configuration])
    }
}
