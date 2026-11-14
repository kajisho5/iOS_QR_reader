import Foundation

/// The codes shown on Apple Watch (docs/DESIGN_1.2.md §8, K). The iPhone draws each code (the watch has no
/// Core Image) and sends the list with WatchConnectivity to the paired watch; nothing goes through a server.
struct WatchCode: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var kindTitle: String
    /// PNG, black on white.
    var image: Data
}

enum WatchCodes {
    /// Key of the application context sent to the watch.
    static let contextKey = "codes"
    /// At most this many codes go to the watch.
    static let limit = 10

    static func encode(_ codes: [WatchCode]) throws -> Data {
        try JSONEncoder().encode(Array(codes.prefix(limit)))
    }

    static func decode(_ data: Data) -> [WatchCode] {
        (try? JSONDecoder().decode([WatchCode].self, from: data)) ?? []
    }
}
