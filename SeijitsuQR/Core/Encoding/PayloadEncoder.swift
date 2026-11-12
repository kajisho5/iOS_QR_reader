import Foundation

/// What the user can create. Text and URL are free; the others need Pro.
enum CreateKind: String, CaseIterable, Identifiable, Sendable {
    case text
    case url
    case wifi
    case contact
    case event
    case email
    case phone
    case sms
    case geo

    var id: String { rawValue }
    var requiresPro: Bool { self != .text && self != .url }

    var payloadKind: PayloadKind {
        switch self {
        case .text: .text
        case .url: .url
        case .wifi: .wifi
        case .contact: .contact
        case .event: .event
        case .email: .email
        case .phone: .phone
        case .sms: .sms
        case .geo: .geo
        }
    }
}

struct WiFiDraft: Equatable, Sendable {
    var ssid = ""
    var password = ""
    var security: WiFiNetwork.Security = .wpa
    var isHidden = false
}

struct ContactDraft: Equatable, Sendable {
    var familyName = ""
    var givenName = ""
    var organization = ""
    var jobTitle = ""
    var phone = ""
    var email = ""
    var url = ""
    var address = ""
    var note = ""
}

struct EmailDraft: Equatable, Sendable {
    var address = ""
    var subject = ""
    var body = ""
}

struct SMSDraft: Equatable, Sendable {
    var number = ""
    var body = ""
}

/// Latitude and longitude as typed (decimal degrees), plus an optional label.
struct GeoDraft: Equatable, Sendable {
    var latitude = ""
    var longitude = ""
    var name = ""
}

struct EventDraft: Equatable, Sendable {
    var title = ""
    var location = ""
    var notes = ""
    var start: Date
    var end: Date
    var isAllDay = false
}

/// Turns form input into the string stored in a QR code. Returns nil when required input is missing.
/// Formats are the ones the parser (and the iOS camera) read: WIFI:, vCard 3.0, iCalendar VEVENT.
enum PayloadEncoder {
    static func text(_ text: String) -> String? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }

    /// Adds https:// when no scheme was typed; only http and https are accepted.
    static func url(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard PayloadParser.parseWebURL(candidate) != nil else { return nil }
        return candidate
    }

    static func wifi(_ draft: WiFiDraft) -> String? {
        let ssid = draft.ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ssid.isEmpty else { return nil }
        var fields: [String]
        switch draft.security {
        case .open:
            fields = ["T:nopass", "S:\(escapeWiFi(ssid))"]
        case .wpa, .wep:
            guard !draft.password.isEmpty else { return nil }
            fields = ["T:\(draft.security == .wep ? "WEP" : "WPA")", "S:\(escapeWiFi(ssid))", "P:\(escapeWiFi(draft.password))"]
        }
        if draft.isHidden { fields.append("H:true") }
        return "WIFI:" + fields.joined(separator: ";") + ";;"
    }

    static func contact(_ draft: ContactDraft) -> String? {
        let d = draft.trimmed
        guard !(d.familyName + d.givenName + d.organization + d.phone + d.email).isEmpty else { return nil }
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append("N:\(escapeText(d.familyName));\(escapeText(d.givenName));;;")
        let fullName = [d.familyName, d.givenName].filter { !$0.isEmpty }.joined(separator: " ")
        lines.append("FN:\(escapeText(fullName.isEmpty ? d.organization : fullName))")
        if !d.organization.isEmpty { lines.append("ORG:\(escapeText(d.organization))") }
        if !d.jobTitle.isEmpty { lines.append("TITLE:\(escapeText(d.jobTitle))") }
        if !d.phone.isEmpty { lines.append("TEL;TYPE=CELL:\(escapeText(d.phone))") }
        if !d.email.isEmpty { lines.append("EMAIL:\(escapeText(d.email))") }
        if !d.url.isEmpty { lines.append("URL:\(escapeText(d.url))") }
        if !d.address.isEmpty { lines.append("ADR:;;\(escapeText(d.address));;;;") }
        if !d.note.isEmpty { lines.append("NOTE:\(escapeText(d.note))") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n")
    }

    /// Timed events are written in UTC; all-day events use calendar dates (end is exclusive).
    static func event(_ draft: EventDraft, calendar: Calendar = .current) -> String? {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, draft.end >= draft.start else { return nil }
        var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "BEGIN:VEVENT", "SUMMARY:\(escapeText(title))"]
        if draft.isAllDay {
            let startDay = calendar.startOfDay(for: draft.start)
            let endDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: draft.end)) ?? startDay
            lines.append("DTSTART;VALUE=DATE:\(dateStamp(startDay, calendar: calendar))")
            lines.append("DTEND;VALUE=DATE:\(dateStamp(endDay, calendar: calendar))")
        } else {
            lines.append("DTSTART:\(utcStamp(draft.start))")
            lines.append("DTEND:\(utcStamp(draft.end))")
        }
        let location = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !location.isEmpty { lines.append("LOCATION:\(escapeText(location))") }
        let notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty { lines.append("DESCRIPTION:\(escapeText(notes))") }
        lines += ["END:VEVENT", "END:VCALENDAR"]
        return lines.joined(separator: "\r\n")
    }

    /// `mailto:` (RFC 6068): the address is required; subject and body are percent-encoded.
    static func email(_ draft: EmailDraft) -> String? {
        let address = draft.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isEmailAddress(address) else { return nil }
        var query: [String] = []
        let subject = draft.subject.trimmingCharacters(in: .whitespacesAndNewlines)
        if !subject.isEmpty { query.append("subject=" + percentEncode(subject)) }
        let body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty { query.append("body=" + percentEncode(body)) }
        return "mailto:" + address + (query.isEmpty ? "" : "?" + query.joined(separator: "&"))
    }

    /// `tel:` with the dialable characters only (digits, +, *, #); spaces, hyphens and brackets are dropped.
    static func phone(_ number: String) -> String? {
        guard let dialable = dialableNumber(number) else { return nil }
        return "tel:" + dialable
    }

    /// `SMSTO:number:body` (the form most scanners, including the iOS camera, read).
    static func sms(_ draft: SMSDraft) -> String? {
        guard let number = dialableNumber(draft.number) else { return nil }
        let body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return "SMSTO:" + number + ":" + body
    }

    /// `geo:lat,lon` (RFC 5870); with a name, `?q=lat,lon(name)` so map apps show the label.
    static func geo(_ draft: GeoDraft) -> String? {
        guard let latitude = coordinate(draft.latitude, limit: 90),
              let longitude = coordinate(draft.longitude, limit: 180) else { return nil }
        let point = "\(latitude),\(longitude)"
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "(", with: "（").replacingOccurrences(of: ")", with: "）")
        return "geo:" + point + (name.isEmpty ? "" : "?q=" + percentEncode(point + "(" + name + ")"))
    }

    /// A typed coordinate in decimal degrees within ±limit, normalized (no exponent, at most 6 decimals).
    static func coordinate(_ input: String, limit: Double) -> String? {
        let typed = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "，", with: ".")
        guard !typed.isEmpty, typed.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" || $0 == "+" }),
              let value = Double(typed), value.isFinite, abs(value) <= limit else { return nil }
        return format(value)
    }

    static func format(_ degrees: Double) -> String {
        var text = String(format: "%.6f", degrees)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text == "-0" ? "0" : text
    }

    private static func dialableNumber(_ input: String) -> String? {
        let kept = input.filter { $0.isASCII && ($0.isNumber || "+*#".contains($0)) }
        return kept.contains(where: \.isNumber) ? kept : nil
    }

    private static func isEmailAddress(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !value.contains(where: \.isWhitespace)
    }

    /// Percent-encodes everything except RFC 3986 unreserved characters (so `&`, `=`, `?` and `+` in text survive).
    static func percentEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    // MARK: Escaping

    /// WIFI: special characters are \ ; , : " (escaped with a backslash).
    static func escapeWiFi(_ value: String) -> String {
        var result = ""
        for ch in value {
            if "\\;,:\"".contains(ch) { result.append("\\") }
            result.append(ch)
        }
        return result
    }

    /// vCard / iCalendar TEXT values: backslash, semicolon, comma and newlines.
    static func escapeText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func utcStamp(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(format: "%04d%02d%02dT%02d%02d%02dZ", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }

    private static func dateStamp(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

private extension ContactDraft {
    var trimmed: ContactDraft {
        func t(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
        return ContactDraft(
            familyName: t(familyName), givenName: t(givenName), organization: t(organization), jobTitle: t(jobTitle),
            phone: t(phone), email: t(email), url: t(url), address: t(address), note: t(note)
        )
    }
}
