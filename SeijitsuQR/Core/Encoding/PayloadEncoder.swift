import Foundation

/// What the user can create. Text and URL are free; the others need Pro.
enum CreateKind: String, CaseIterable, Identifiable, Sendable {
    case text
    case url
    case wifi
    case contact
    case event

    var id: String { rawValue }
    var requiresPro: Bool { self == .wifi || self == .contact || self == .event }

    var payloadKind: PayloadKind {
        switch self {
        case .text: .text
        case .url: .url
        case .wifi: .wifi
        case .contact: .contact
        case .event: .event
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
