import Foundation

/// What the home screen widget may show (docs/DESIGN_1.1.md §4, B): the favorites and whether Pro is unlocked.
/// The app writes it to the shared App Group container; the widget only reads it. The history store itself is
/// never moved or opened by the widget.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct Favorite: Codable, Equatable, Hashable, Sendable, Identifiable {
        var id: UUID
        /// A short name: the network name, the domain, or the start of the content.
        var title: String
        /// The kind's name as the app shows it ("Wi-Fi", "URL", …).
        var kindTitle: String
        var symbologyRaw: String?
        /// The exact content of the code (drawn again by the widget).
        var content: String
    }

    var isPro: Bool
    var favorites: [Favorite]

    static let appGroup = "group.com.seventhwell.seijitsuqr"

    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appending(path: "WidgetSnapshot.json")
    }

    static func load(from url: URL? = fileURL) -> WidgetSnapshot? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(to url: URL? = Self.fileURL) throws {
        guard let url else { throw CocoaError(.fileNoSuchFile) }
        let data = try JSONEncoder().encode(self)
        // Readable by the widget even while the iPhone is locked (it is on the home screen).
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
