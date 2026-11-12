import Foundation

/// A code read in the share extension, waiting to be added to the history the next time the app opens
/// (docs/DESIGN_1.1.md §5, E). The extension never opens the history store itself.
struct PendingScan: Codable, Equatable, Sendable {
    var content: String
    var symbologyRaw: String
    var date: Date
}

/// The queue of pending scans, kept in the shared keychain group (see SharedKeychain) or a file (tests).
enum PendingScans {
    /// The queue keeps the newest this many; older ones are dropped.
    static let limit = 50
    private static let account = "pending-scans"

    static func load(from store: WidgetSnapshot.Store = .keychain) -> [PendingScan] {
        let data: Data?
        switch store {
        case .keychain: data = SharedKeychain.read(account: account)
        case .file(let url): data = try? Data(contentsOf: url)
        }
        guard let data else { return [] }
        return (try? JSONDecoder().decode([PendingScan].self, from: data)) ?? []
    }

    static func append(_ scan: PendingScan, to store: WidgetSnapshot.Store = .keychain) throws {
        var queue = load(from: store)
        queue.removeAll { $0.content == scan.content && $0.symbologyRaw == scan.symbologyRaw }
        queue.append(scan)
        try save(Array(queue.suffix(limit)), to: store)
    }

    /// Returns the queue (oldest first) and empties it.
    static func takeAll(from store: WidgetSnapshot.Store = .keychain) -> [PendingScan] {
        let queue = load(from: store)
        guard !queue.isEmpty else { return [] }
        switch store {
        case .keychain: SharedKeychain.delete(account: account)
        case .file(let url): try? FileManager.default.removeItem(at: url)
        }
        return queue
    }

    private static func save(_ queue: [PendingScan], to store: WidgetSnapshot.Store) throws {
        let data = try JSONEncoder().encode(queue)
        switch store {
        case .keychain: try SharedKeychain.write(data, account: account)
        case .file(let url): try data.write(to: url, options: .atomic)
        }
    }
}
