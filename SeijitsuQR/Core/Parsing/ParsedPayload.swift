import Foundation

/// A decoded code, classified into one of the supported content kinds.
enum ParsedPayload: Equatable, Sendable {
    case url(URL)
    case wifi(WiFiNetwork)
    case contact(ContactCard)
    case email(EmailMessage)
    case phone(String)
    case sms(SMSMessage)
    case geo(GeoPoint)
    case event(String)
    case text(String)

    var kind: PayloadKind {
        switch self {
        case .url: .url
        case .wifi: .wifi
        case .contact: .contact
        case .email: .email
        case .phone: .phone
        case .sms: .sms
        case .geo: .geo
        case .event: .event
        case .text: .text
        }
    }
}

struct WiFiNetwork: Equatable, Sendable {
    enum Security: Equatable, Sendable {
        /// WPA, WPA2 and WPA3 personal all join with a passphrase.
        case wpa
        case wep
        case open
    }

    var ssid: String
    var password: String?
    var security: Security
    var isHidden: Bool
}

struct ContactCard: Equatable, Sendable {
    var formattedName: String?
    var familyName: String?
    var givenName: String?
    var phoneticName: String?
    var organization: String?
    var jobTitle: String?
    var phoneNumbers: [String] = []
    var emails: [String] = []
    var urls: [String] = []
    var addresses: [String] = []
    var note: String?

    /// The best single-line name for display, falling back to the organization.
    var displayName: String? {
        if let formattedName, !formattedName.isEmpty { return formattedName }
        let joined = [familyName, givenName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        if !joined.isEmpty { return joined }
        return organization
    }
}

struct EmailMessage: Equatable, Sendable {
    var address: String
    var subject: String?
    var body: String?
}

struct SMSMessage: Equatable, Sendable {
    var number: String
    var body: String?
}

struct GeoPoint: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
    var query: String?
}
