import Foundation

/// Classifies the raw string of a scanned code. Pure and synchronous: no network, no side effects.
enum PayloadParser {
    static func parse(_ raw: String) -> ParsedPayload {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()

        if upper.hasPrefix("WIFI:"), let network = parseWiFi(trimmed) {
            return .wifi(network)
        }
        if upper.hasPrefix("BEGIN:VCARD"), let card = parseVCard(trimmed) {
            return .contact(card)
        }
        if upper.hasPrefix("MECARD:"), let card = parseMECARD(trimmed) {
            return .contact(card)
        }
        if upper.hasPrefix("MAILTO:"), let message = parseMailto(trimmed) {
            return .email(message)
        }
        if upper.hasPrefix("MATMSG:"), let message = parseMATMSG(trimmed) {
            return .email(message)
        }
        if upper.hasPrefix("TEL:"), let number = parseTel(trimmed) {
            return .phone(number)
        }
        if upper.hasPrefix("SMSTO:") || upper.hasPrefix("SMS:"), let message = parseSMS(trimmed) {
            return .sms(message)
        }
        if upper.hasPrefix("GEO:"), let point = parseGeo(trimmed) {
            return .geo(point)
        }
        if upper.hasPrefix("BEGIN:VCALENDAR") || upper.hasPrefix("BEGIN:VEVENT") {
            return .event(trimmed)
        }
        if let url = parseWebURL(trimmed) {
            return .url(url)
        }
        return .text(raw)
    }

    // MARK: - URL

    /// Only http and https are treated as links; any other scheme stays plain text (no "open" action).
    static func parseWebURL(_ string: String) -> URL? {
        guard !string.contains(where: \.isWhitespace),
              let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty
        else { return nil }
        return url
    }

    // MARK: - Wi-Fi (WIFI:T:WPA;S:ssid;P:pass;H:true;;)

    static func parseWiFi(_ string: String) -> WiFiNetwork? {
        let fields = keyValueFields(String(string.dropFirst("WIFI:".count)))
        guard let ssid = fields["S"], !ssid.isEmpty else { return nil }
        let type = (fields["T"] ?? "").uppercased()
        let security: WiFiNetwork.Security
        switch type {
        case "WEP": security = .wep
        case "", "NOPASS": security = (fields["P"]?.isEmpty == false) ? .wpa : .open
        default: security = .wpa
        }
        let password = security == .open ? nil : fields["P"]
        let hidden = (fields["H"] ?? "").lowercased() == "true"
        return WiFiNetwork(ssid: ssid, password: password, security: security, isHidden: hidden)
    }

    // MARK: - MECARD / MATMSG

    static func parseMECARD(_ string: String) -> ContactCard? {
        let body = String(string.dropFirst("MECARD:".count))
        var card = ContactCard()
        for (key, value) in orderedKeyValueFields(body) where !value.isEmpty {
            switch key {
            case "N":
                let parts = value.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
                card.familyName = parts.first
                if parts.count > 1 { card.givenName = parts[1] }
            case "SOUND": card.phoneticName = value.replacingOccurrences(of: ",", with: " ")
            case "TEL", "TEL-AV": card.phoneNumbers.append(value)
            case "EMAIL": card.emails.append(value)
            case "URL": card.urls.append(value)
            case "ADR": card.addresses.append(value.replacingOccurrences(of: ",", with: " ").trimmingCharacters(in: .whitespaces))
            case "ORG": card.organization = value
            case "NOTE": card.note = value
            default: break
            }
        }
        return card.displayName == nil && card.phoneNumbers.isEmpty && card.emails.isEmpty ? nil : card
    }

    static func parseMATMSG(_ string: String) -> EmailMessage? {
        let fields = keyValueFields(String(string.dropFirst("MATMSG:".count)))
        guard let address = fields["TO"], !address.isEmpty else { return nil }
        return EmailMessage(address: address, subject: fields["SUB"].nilIfEmpty, body: fields["BODY"].nilIfEmpty)
    }

    /// Splits `K:V;K:V;;` on unescaped semicolons and unescapes `\;` `\,` `\:` `\\` `\"`.
    static func orderedKeyValueFields(_ body: String) -> [(String, String)] {
        splitUnescaped(body, separator: ";").compactMap { field in
            guard let colon = firstUnescapedIndex(of: ":", in: field) else { return nil }
            let key = String(field[..<colon]).trimmingCharacters(in: .whitespaces).uppercased()
            let value = unescapeMeCard(String(field[field.index(after: colon)...]))
            return key.isEmpty ? nil : (key, value)
        }
    }

    static func keyValueFields(_ body: String) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in orderedKeyValueFields(body) where result[key] == nil {
            result[key] = value
        }
        return result
    }

    private static func splitUnescaped(_ string: String, separator: Character) -> [String] {
        var parts: [String] = []
        var current = ""
        var escaping = false
        for ch in string {
            if escaping {
                current.append("\\")
                current.append(ch)
                escaping = false
            } else if ch == "\\" {
                escaping = true
            } else if ch == separator {
                parts.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        if escaping { current.append("\\") }
        if !current.isEmpty { parts.append(current) }
        return parts
    }

    private static func firstUnescapedIndex(of target: Character, in string: String) -> String.Index? {
        var escaping = false
        var index = string.startIndex
        while index < string.endIndex {
            let ch = string[index]
            if escaping {
                escaping = false
            } else if ch == "\\" {
                escaping = true
            } else if ch == target {
                return index
            }
            index = string.index(after: index)
        }
        return nil
    }

    private static func unescapeMeCard(_ value: String) -> String {
        var result = ""
        var escaping = false
        for ch in value {
            if escaping {
                result.append(ch)
                escaping = false
            } else if ch == "\\" {
                escaping = true
            } else {
                result.append(ch)
            }
        }
        return result
    }

    // MARK: - vCard (2.1 / 3.0 / 4.0)

    static func parseVCard(_ string: String) -> ContactCard? {
        var card = ContactCard()
        for line in unfoldedVCardLines(string) {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let left = line[..<colon]
            var value = String(line[line.index(after: colon)...])
            let leftParts = left.split(separator: ";").map(String.init)
            guard var name = leftParts.first?.uppercased() else { continue }
            if let dot = name.lastIndex(of: ".") { name = String(name[name.index(after: dot)...]) }
            let params = leftParts.dropFirst().map { $0.uppercased() }
            if params.contains(where: { $0.contains("QUOTED-PRINTABLE") }) {
                value = decodeQuotedPrintable(value) ?? value
            }
            switch name {
            case "FN": card.formattedName = unescapeVCard(value).nilIfEmpty
            case "N":
                let parts = splitVCardComponents(value)
                card.familyName = parts.first.nilIfEmpty
                if parts.count > 1 { card.givenName = parts[1].nilIfEmpty }
            case "ORG": card.organization = splitVCardComponents(value).filter { !$0.isEmpty }.joined(separator: " ").nilIfEmpty
            case "TITLE": card.jobTitle = unescapeVCard(value).nilIfEmpty
            case "TEL": if let v = unescapeVCard(value).nilIfEmpty { card.phoneNumbers.append(v.replacingOccurrences(of: "tel:", with: "")) }
            case "EMAIL": if let v = unescapeVCard(value).nilIfEmpty { card.emails.append(v) }
            case "URL": if let v = unescapeVCard(value).nilIfEmpty { card.urls.append(v) }
            case "ADR":
                // pobox;ext;street;locality;region;postal;country -> Japanese reading order
                let p = splitVCardComponents(value) + Array(repeating: "", count: 7)
                let ordered = [p[5], p[6], p[4], p[3], p[2], p[1], p[0]].filter { !$0.isEmpty }
                if !ordered.isEmpty { card.addresses.append(ordered.joined(separator: " ")) }
            case "NOTE": card.note = unescapeVCard(value).nilIfEmpty
            case "X-PHONETIC-LAST-NAME", "X-PHONETIC-FIRST-NAME":
                let v = unescapeVCard(value)
                card.phoneticName = [card.phoneticName, v].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ").nilIfEmpty
            default: break
            }
        }
        let hasContent = card.displayName != nil || !card.phoneNumbers.isEmpty || !card.emails.isEmpty
        return hasContent ? card : nil
    }

    /// Normalizes line endings and joins folded lines (RFC 6350 3.2) and quoted-printable soft breaks.
    static func unfoldedVCardLines(_ string: String) -> [String] {
        let normalized = string.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines: [String] = []
        for rawLine in normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if let first = rawLine.first, first == " " || first == "\t", !lines.isEmpty {
                lines[lines.count - 1] += String(rawLine.dropFirst())
            } else if let last = lines.last, last.uppercased().contains("QUOTED-PRINTABLE"), last.hasSuffix("=") {
                lines[lines.count - 1] = String(last.dropLast()) + rawLine
            } else {
                lines.append(rawLine)
            }
        }
        return lines.filter { !$0.isEmpty }
    }

    private static func splitVCardComponents(_ value: String) -> [String] {
        splitUnescaped(value, separator: ";").map(unescapeVCard)
            + (value.hasSuffix(";") ? [""] : [])
    }

    private static func unescapeVCard(_ value: String) -> String {
        var result = ""
        var escaping = false
        for ch in value {
            if escaping {
                switch ch {
                case "n", "N": result.append("\n")
                default: result.append(ch)
                }
                escaping = false
            } else if ch == "\\" {
                escaping = true
            } else {
                result.append(ch)
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    static func decodeQuotedPrintable(_ value: String) -> String? {
        var bytes: [UInt8] = []
        var iterator = Array(value.utf8).makeIterator()
        while let byte = iterator.next() {
            if byte == UInt8(ascii: "=") {
                guard let h = iterator.next(), let l = iterator.next(),
                      let hi = hexValue(h), let lo = hexValue(l) else { return nil }
                bytes.append(hi << 4 | lo)
            } else {
                bytes.append(byte)
            }
        }
        return String(bytes: bytes, encoding: .utf8)
    }

    private static func hexValue(_ c: UInt8) -> UInt8? {
        switch c {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): c - UInt8(ascii: "0")
        case UInt8(ascii: "A")...UInt8(ascii: "F"): c - UInt8(ascii: "A") + 10
        case UInt8(ascii: "a")...UInt8(ascii: "f"): c - UInt8(ascii: "a") + 10
        default: nil
        }
    }

    // MARK: - mailto / tel / sms / geo

    static func parseMailto(_ string: String) -> EmailMessage? {
        let rest = String(string.dropFirst("mailto:".count))
        let parts = rest.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let address = (String(parts[0]).removingPercentEncoding ?? String(parts[0])).trimmingCharacters(in: .whitespaces)
        guard !address.isEmpty else { return nil }
        let query = parts.count > 1 ? queryParameters(String(parts[1])) : [:]
        return EmailMessage(address: address, subject: query["subject"].nilIfEmpty, body: query["body"].nilIfEmpty)
    }

    static func parseTel(_ string: String) -> String? {
        let rest = String(string.dropFirst("tel:".count))
        let number = (rest.removingPercentEncoding ?? rest).trimmingCharacters(in: .whitespaces)
        return number.isEmpty ? nil : number
    }

    static func parseSMS(_ string: String) -> SMSMessage? {
        let upper = string.uppercased()
        if upper.hasPrefix("SMSTO:") {
            let rest = String(string.dropFirst("SMSTO:".count))
            let parts = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let number = String(parts[0]).trimmingCharacters(in: .whitespaces)
            guard !number.isEmpty else { return nil }
            return SMSMessage(number: number, body: parts.count > 1 ? String(parts[1]).nilIfEmpty : nil)
        }
        let rest = String(string.dropFirst("sms:".count))
        let separatorIndex = rest.firstIndex(where: { $0 == "?" || $0 == "&" })
        let numberPart = separatorIndex.map { String(rest[..<$0]) } ?? rest
        let number = (numberPart.removingPercentEncoding ?? numberPart).trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return nil }
        var body: String?
        if let separatorIndex {
            body = queryParameters(String(rest[rest.index(after: separatorIndex)...]))["body"].nilIfEmpty
        }
        return SMSMessage(number: number, body: body)
    }

    static func parseGeo(_ string: String) -> GeoPoint? {
        let rest = String(string.dropFirst("geo:".count))
        let parts = rest.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let coordinatePart = parts[0].split(separator: ";").first.map(String.init) ?? ""
        let numbers = coordinatePart.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count >= 2, let lat = numbers[0], let lon = numbers[1],
              (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        let query = parts.count > 1 ? queryParameters(String(parts[1]))["q"].nilIfEmpty : nil
        return GeoPoint(latitude: lat, longitude: lon, query: query)
    }

    /// Parses `a=b&c=d` with percent-decoding; `+` is read as a space. Keys are lowercased.
    static func queryParameters(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(kv[0]).lowercased()
            let rawValue = kv.count > 1 ? String(kv[1]).replacingOccurrences(of: "+", with: " ") : ""
            if result[key] == nil { result[key] = rawValue.removingPercentEncoding ?? rawValue }
        }
        return result
    }
}

private extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
