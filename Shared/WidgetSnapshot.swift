import Foundation
import Security

/// What the home screen widget may show (docs/DESIGN_1.1.md §4, B): the favorites and whether Pro is unlocked.
/// The app writes it; the widget only reads it. The history store itself is never moved or opened by the widget.
///
/// It is passed through a Keychain item shared by the app and the extension (a keychain access group under the
/// team's prefix), not an App Group: App Group identifiers cannot be registered through the App Store Connect
/// API that the CI signing uses, while the team's keychain groups are allowed by every provisioning profile.
/// The item never leaves the device (ThisDeviceOnly) and can be read after the first unlock, while locked.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct Favorite: Codable, Equatable, Hashable, Sendable, Identifiable {
        var id: UUID
        /// A short name: the note, the network name, the domain, or the start of the content.
        var title: String
        /// The kind's name as the app shows it ("Wi-Fi", "URL", …).
        var kindTitle: String
        var symbologyRaw: String?
        /// The exact content of the code (drawn again by the widget).
        var content: String
    }

    var isPro: Bool
    var favorites: [Favorite]

    /// Where the snapshot is kept: the shared Keychain item (the app and the widget), or a file (tests).
    enum Store: Sendable {
        case keychain
        case file(URL)
    }

    static func load(from store: Store = .keychain) -> WidgetSnapshot? {
        let data: Data?
        switch store {
        case .keychain: data = SharedKeychain.read(account: Self.account)
        case .file(let url): data = try? Data(contentsOf: url)
        }
        guard let data else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(to store: Store = .keychain) throws {
        let data = try JSONEncoder().encode(self)
        switch store {
        case .keychain: try SharedKeychain.write(data, account: Self.account)
        case .file(let url): try data.write(to: url, options: .atomic)
        }
    }

    private static let account = "widget-snapshot"
}

/// Generic-password items in the keychain group shared by the app and its extensions (one per account).
enum SharedKeychain {
    struct Failure: Error {
        let status: OSStatus
    }

    private static let service = "com.seventhwell.seijitsuqr.shared"

    /// `$(AppIdentifierPrefix)com.seventhwell.seijitsuqr.shared`, written into each target's Info.plist at build time.
    static var accessGroup: String? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "SeijitsuSharedKeychainGroup") as? String,
              !group.hasPrefix("$(") else { return nil }
        return group
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }

    static func read(account: String) -> Data? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func write(_ data: Data, account: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(baseQuery(account) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let added = SecItemAdd(baseQuery(account).merging(attributes) { $1 } as CFDictionary, nil)
            guard added == errSecSuccess else { throw Failure(status: added) }
        } else if status != errSecSuccess {
            throw Failure(status: status)
        }
    }

    static func delete(account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }
}
