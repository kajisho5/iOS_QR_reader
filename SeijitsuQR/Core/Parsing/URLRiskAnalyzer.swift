import Foundation

/// Something about a URL worth knowing before opening it. Found from the text of the URL alone:
/// nothing is looked up on the network (docs/DESIGN_1.1.md §2).
struct URLRisk: Equatable, Hashable, Sendable {
    enum Kind: Equatable, Hashable, Sendable {
        /// The host uses non-ASCII characters (an internationalized domain), which can imitate another domain.
        case lookalikeCharacters(shown: String, actual: String)
        /// Text before an "@" in the authority looks like a host but is only a user name.
        case disguisedHost(shown: String, actual: String)
        /// A link shortener: where it leads is unknown until it is opened.
        case shortener(host: String)
        /// Plain http: not encrypted.
        case insecure
        /// The host is an IP address instead of a domain name.
        case ipAddress(String)
        /// A port other than the scheme's standard one.
        case unusualPort(Int)
    }

    enum Severity: Int, Comparable, Sendable {
        case caution
        case warning

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let kind: Kind

    var severity: Severity {
        switch kind {
        case .lookalikeCharacters, .disguisedHost: .warning
        case .shortener, .insecure, .ipAddress, .unusualPort: .caution
        }
    }
}

enum URLRiskAnalyzer {
    /// Well-known link shorteners. Matched against the whole host or its parent domain.
    static let shorteners: Set<String> = [
        "bit.ly", "bitly.com", "t.co", "tinyurl.com", "goo.gl", "ow.ly", "is.gd", "buff.ly", "cutt.ly",
        "rebrand.ly", "x.gd", "t.ly", "s.id", "rb.gy", "shorturl.at", "tiny.cc", "v.gd", "lnkd.in", "dlvr.it",
        "amzn.to", "amzn.asia", "youtu.be", "qrco.de", "qr.paps.jp",
    ]

    /// Risks in `raw` (the scanned text) parsed as `url`, most serious first. Empty when there is nothing to say.
    static func risks(in raw: String, url: URL) -> [URLRisk] {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let authority = Authority(text)
        let host = (url.host ?? authority.host).lowercased()
        var risks: [URLRisk] = []

        // Internationalized domain: shown with non-ASCII letters, or already in punycode ("xn--").
        let shownHost = authority.host
        let hasNonASCII = shownHost.unicodeScalars.contains { !$0.isASCII }
        let hasPunycode = host.split(separator: ".").contains { $0.hasPrefix("xn--") } ||
            shownHost.lowercased().split(separator: ".").contains { $0.hasPrefix("xn--") }
        if hasNonASCII || hasPunycode {
            let actual = hasPunycode && !host.unicodeScalars.contains(where: { !$0.isASCII }) ? host : shownHost
            risks.append(URLRisk(kind: .lookalikeCharacters(shown: shownHost, actual: actual)))
        }

        // "https://www.bank.example@evil.example/": everything before "@" is a user name.
        if let user = authority.userInfo, !user.isEmpty {
            risks.append(URLRisk(kind: .disguisedHost(shown: user, actual: host)))
        }

        let isIP = isIPAddress(host)
        if !isIP, let shortener = shorteners.first(where: { host == $0 || host.hasSuffix("." + $0) }) {
            risks.append(URLRisk(kind: .shortener(host: shortener)))
        }

        let scheme = url.scheme?.lowercased()
        if scheme == "http" {
            risks.append(URLRisk(kind: .insecure))
        }
        if isIP {
            risks.append(URLRisk(kind: .ipAddress(host)))
        }
        if let port = url.port ?? authority.port {
            let standard = scheme == "https" ? 443 : 80
            if port != standard {
                risks.append(URLRisk(kind: .unusualPort(port)))
            }
        }
        // Stable order: warnings first, then in the order found.
        return risks.enumerated().sorted { a, b in
            a.element.severity != b.element.severity ? a.element.severity > b.element.severity : a.offset < b.offset
        }.map(\.element)
    }

    static func isIPAddress(_ host: String) -> Bool {
        let bare = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if bare.contains(":") {
            // IPv6: hex groups and colons (optionally an embedded IPv4 tail).
            return bare.allSatisfy { $0.isHexDigit || $0 == ":" || $0 == "." } && bare.filter({ $0 == ":" }).count >= 2
        }
        let parts = bare.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts.allSatisfy { part in
            guard !part.isEmpty, part.count <= 3, part.allSatisfy(\.isASCII), let value = Int(part) else { return false }
            return (0...255).contains(value)
        }
    }

    /// The authority part of the raw text ("user@host:port"), read without any decoding, so the host is
    /// shown exactly as it appears in the code.
    struct Authority {
        var userInfo: String?
        var host = ""
        var port: Int?

        init(_ text: String) {
            guard let range = text.range(of: "://") else { return }
            let rest = text[range.upperBound...]
            let end = rest.firstIndex(where: { $0 == "/" || $0 == "?" || $0 == "#" }) ?? rest.endIndex
            var authority = String(rest[..<end])
            if let at = authority.lastIndex(of: "@") {
                userInfo = String(authority[..<at])
                authority = String(authority[authority.index(after: at)...])
            }
            if authority.hasPrefix("["), let close = authority.firstIndex(of: "]") {
                host = String(authority[...close])
                let after = authority[authority.index(after: close)...]
                if after.hasPrefix(":") { port = Int(after.dropFirst()) }
            } else if let colon = authority.lastIndex(of: ":") {
                host = String(authority[..<colon])
                port = Int(authority[authority.index(after: colon)...])
            } else {
                host = authority
            }
        }
    }
}
