import Foundation

/// Counting codes while scanning (docs/DESIGN_1.2.md §5, I; docs/design/26_stocktake.svg). Pure state: the
/// scanner feeds every detection, and a code counts again only after it has been out of view for `gap` seconds,
/// so holding one code in front of the camera counts it once.
struct StocktakeSession: Equatable, Sendable {
    struct Item: Equatable, Identifiable, Sendable {
        var code: DetectedCode
        var count: Int
        var lastCounted: Date

        var id: String { code.dedupeKey }
    }

    static let gap: TimeInterval = 1.0

    /// Newest first.
    private(set) var items: [Item] = []
    private(set) var startedAt: Date?
    private var lastSeen: [String: Date] = [:]

    var total: Int { items.reduce(0) { $0 + $1.count } }
    var isEmpty: Bool { items.isEmpty }

    /// Records one detection. Returns the item's new count when this detection counted, nil when the code was
    /// still in view (seen less than `gap` seconds ago).
    @discardableResult
    mutating func observe(_ code: DetectedCode, at date: Date = .now) -> Int? {
        let key = code.dedupeKey
        defer { lastSeen[key] = date }
        if let seen = lastSeen[key], date.timeIntervalSince(seen) < Self.gap { return nil }
        if startedAt == nil { startedAt = date }
        if let index = items.firstIndex(where: { $0.id == key }) {
            var item = items.remove(at: index)
            item.count += 1
            item.lastCounted = date
            items.insert(item, at: 0)
            return item.count
        }
        items.insert(Item(code: code, count: 1, lastCounted: date), at: 0)
        return 1
    }

    mutating func increment(_ id: Item.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].count += 1
    }

    /// Down to 1; removing an item is a separate action.
    mutating func decrement(_ id: Item.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].count > 1 else { return }
        items[index].count -= 1
    }

    mutating func remove(_ id: Item.ID) {
        items.removeAll { $0.id == id }
    }

    /// The counts as CSV: UTF-8 with BOM, CRLF, the same quoting as the history export.
    func csv(headers: [String], kindTitle: (DetectedCode) -> String, symbologyTitle: (CodeSymbology) -> String, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        func stamp(_ date: Date) -> String {
            let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            return String(format: "%04d-%02d-%02d %02d:%02d:%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
        }
        var lines = [headers.map(CSVExporter.escape).joined(separator: ",")]
        for item in items.reversed() {
            let fields = [item.code.content, kindTitle(item.code), symbologyTitle(item.code.symbology), String(item.count), stamp(item.lastCounted)]
            lines.append(fields.map(CSVExporter.escape).joined(separator: ","))
        }
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }
}
