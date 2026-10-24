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
