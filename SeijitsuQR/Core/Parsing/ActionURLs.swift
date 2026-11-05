import Foundation

/// Builds the system URLs used by result actions. Nothing is opened until the user taps a button.
enum ActionURLs {
    static func mail(_ message: EmailMessage) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = message.address
        var items: [URLQueryItem] = []
        if let subject = message.subject { items.append(URLQueryItem(name: "subject", value: subject)) }
        if let body = message.body { items.append(URLQueryItem(name: "body", value: body)) }
        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }

    /// Keeps only characters valid in a dial string so a crafted code cannot inject other URL parts.
    static func phone(_ number: String) -> URL? {
        let allowed = Set("0123456789+*#,;")
        let digits = String(number.filter { allowed.contains($0) })
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    static func sms(_ message: SMSMessage) -> URL? {
        let allowed = Set("0123456789+*#")
        let digits = String(message.number.filter { allowed.contains($0) })
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms:\(digits)")
    }

    /// Opens Apple Maps at the coordinate (maps.apple.com is handed to the Maps app by the system).
    static func maps(_ point: GeoPoint) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        var items = [URLQueryItem(name: "ll", value: "\(point.latitude),\(point.longitude)")]
        if let query = point.query { items.append(URLQueryItem(name: "q", value: query)) }
        components?.queryItems = items
        return components?.url
    }
}

/// Where "ウェブで検索" sends a product code (docs/DESIGN_1.1.md §2.5). Chosen in Settings; the app itself
/// never connects: the URL is handed to the browser only when the user taps the button.
enum SearchEngine: String, CaseIterable, Identifiable, Sendable {
    case google
    case yahooJapan
    case duckDuckGo
    case bing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .google: L10n.searchEngineGoogle
        case .yahooJapan: L10n.searchEngineYahooJapan
        case .duckDuckGo: L10n.searchEngineDuckDuckGo
        case .bing: L10n.searchEngineBing
        }
    }

    func url(searching query: String) -> URL? {
        let (base, name) = switch self {
        case .google: ("https://www.google.com/search", "q")
        case .yahooJapan: ("https://search.yahoo.co.jp/search", "p")
        case .duckDuckGo: ("https://duckduckgo.com/", "q")
        case .bing: ("https://www.bing.com/search", "q")
        }
        var components = URLComponents(string: base)
        components?.queryItems = [URLQueryItem(name: name, value: query)]
        return components?.url
    }
}

/// Retail barcodes (JAN/EAN/UPC) and the books among them (ISBN-13 = EAN-13 starting with 978 or 979).
enum ProductCode {
    static func isProductCode(_ symbology: CodeSymbology) -> Bool {
        [.ean13, .ean8, .upce].contains(symbology)
    }

    static func isISBN(_ content: String, symbology: CodeSymbology) -> Bool {
        guard symbology == .ean13, content.count == 13, content.allSatisfy(\.isASCII),
              content.hasPrefix("978") || content.hasPrefix("979") else { return false }
        let digits = content.compactMap(\.wholeNumberValue)
        return digits.count == 13 && LinearBarcodeEncoder.gs1CheckDigit(Array(digits.prefix(12))) == digits[12]
    }
}
