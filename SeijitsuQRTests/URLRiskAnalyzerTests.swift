import Foundation
import Testing
@testable import SeijitsuQR

/// URL notes are decided from the text alone (docs/DESIGN_1.1.md §2).
struct URLRiskAnalyzerTests {
    private func kinds(_ raw: String) throws -> [URLRisk.Kind] {
        let url = try #require(PayloadParser.parseWebURL(raw))
        return URLRiskAnalyzer.risks(in: raw, url: url).map(\.kind)
    }

    @Test func plainHTTPSHasNothingToNote() throws {
        #expect(try kinds("https://www.example.co.jp/campaign?ref=qr").isEmpty)
        #expect(try kinds("https://example.com:443/").isEmpty)
    }

    @Test func shortener() throws {
        #expect(try kinds("https://bit.ly/3xAbCdE") == [.shortener(host: "bit.ly")])
        #expect(try kinds("https://www.bit.ly/abc") == [.shortener(host: "bit.ly")])
        // A different domain that merely ends with the same letters is not a shortener.
        #expect(try kinds("https://rabbit.ly.example.com/").isEmpty)
    }

    @Test func insecureAndIPAddressAndPort() throws {
        #expect(try kinds("http://192.168.0.10:8080/admin") == [.insecure, .ipAddress("192.168.0.10"), .unusualPort(8080)])
        #expect(try kinds("http://example.com/") == [.insecure])
        #expect(try kinds("https://example.com:8443/") == [.unusualPort(8443)])
    }

    @Test func disguisedHostComesFirst() throws {
        let found = try kinds("https://www.bank.example@evil.example/login")
        #expect(found.first == .disguisedHost(shown: "www.bank.example", actual: "evil.example"))
    }

    @Test func punycodeHost() throws {
        let found = try kinds("https://xn--pple-43d.com/login")
        #expect(found == [.lookalikeCharacters(shown: "xn--pple-43d.com", actual: "xn--pple-43d.com")])
    }

    @Test func nonASCIIHostIsNotedWhenParsed() throws {
        // Cyrillic "а" in place of the Latin "a". Whether URL(string:) accepts it depends on the OS;
        // when it does, the host must be flagged.
        let raw = "https://\u{0430}pple.com/login"
        guard let url = PayloadParser.parseWebURL(raw) else { return }
        let found = URLRiskAnalyzer.risks(in: raw, url: url)
        #expect(found.first?.severity == .warning)
        if case .lookalikeCharacters(let shown, _) = found.first?.kind {
            #expect(shown == "\u{0430}pple.com")
        } else {
            Issue.record("expected a lookalike note, got \(found)")
        }
    }

    @Test func ipAddressDetection() {
        #expect(URLRiskAnalyzer.isIPAddress("10.0.0.1"))
        #expect(URLRiskAnalyzer.isIPAddress("[2001:db8::1]"))
        #expect(!URLRiskAnalyzer.isIPAddress("256.1.1.1"))
        #expect(!URLRiskAnalyzer.isIPAddress("1.2.3"))
        #expect(!URLRiskAnalyzer.isIPAddress("example.com"))
    }
}
