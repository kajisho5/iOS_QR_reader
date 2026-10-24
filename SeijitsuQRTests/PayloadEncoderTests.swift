import Foundation
import Testing
@testable import SeijitsuQR

struct PayloadEncoderTests {
    @Test func textRejectsBlank() {
        #expect(PayloadEncoder.text("  \n") == nil)
        #expect(PayloadEncoder.text("こんにちは") == "こんにちは")
    }

    @Test func urlAddsHTTPSWhenSchemeIsMissing() {
        #expect(PayloadEncoder.url("www.example.co.jp/path") == "https://www.example.co.jp/path")
        #expect(PayloadEncoder.url("http://example.com") == "http://example.com")
        #expect(PayloadEncoder.url("ftp://example.com") == nil)
        #expect(PayloadEncoder.url("not a url") == nil)
    }

    @Test func wifiRoundTripsThroughTheParser() throws {
        let draft = WiFiDraft(ssid: "Cafe;5G:\"A\"", password: "p,a\\ss", security: .wpa, isHidden: true)
        let encoded = try #require(PayloadEncoder.wifi(draft))
        #expect(PayloadParser.parse(encoded) == .wifi(WiFiNetwork(ssid: "Cafe;5G:\"A\"", password: "p,a\\ss", security: .wpa, isHidden: true)))
    }

    @Test func openWifiHasNoPassword() throws {
        let encoded = try #require(PayloadEncoder.wifi(WiFiDraft(ssid: "Guest", password: "ignored", security: .open)))
        #expect(encoded == "WIFI:T:nopass;S:Guest;;")
    }

    @Test func wifiRequiresSSIDAndPasswordForSecuredNetworks() {
        #expect(PayloadEncoder.wifi(WiFiDraft(ssid: "", password: "x")) == nil)
        #expect(PayloadEncoder.wifi(WiFiDraft(ssid: "Net", password: "", security: .wpa)) == nil)
    }

    @Test func contactRoundTripsThroughTheParser() throws {
        var draft = ContactDraft()
        draft.familyName = "山田"
        draft.givenName = "太郎"
        draft.organization = "誠実商事, 営業部"
        draft.phone = "03-1234-5678"
        draft.email = "taro@example.co.jp"
        draft.note = "1行目\n2行目"
        let encoded = try #require(PayloadEncoder.contact(draft))
        guard case .contact(let card) = PayloadParser.parse(encoded) else { Issue.record("expected contact"); return }
        #expect(card.familyName == "山田")
        #expect(card.givenName == "太郎")
        #expect(card.formattedName == "山田 太郎")
        #expect(card.organization == "誠実商事, 営業部")
        #expect(card.phoneNumbers == ["03-1234-5678"])
        #expect(card.emails == ["taro@example.co.jp"])
        #expect(card.note == "1行目\n2行目")
    }

    @Test func contactNeedsSomeIdentity() {
        #expect(PayloadEncoder.contact(ContactDraft(note: "only a note")) == nil)
    }

    @Test func timedEventIsWrittenInUTC() throws {
        let start = Date(timeIntervalSince1970: 1_793_000_000)
        let draft = EventDraft(title: "会議, 定例", location: "本社", notes: "", start: start, end: start.addingTimeInterval(3600))
        let encoded = try #require(PayloadEncoder.event(draft))
        #expect(encoded.contains("SUMMARY:会議\\, 定例"))
        #expect(encoded.contains("DTSTART:20261026T073320Z"))
        #expect(encoded.contains("DTEND:20261026T083320Z"))
        #expect(encoded.hasSuffix("END:VEVENT\r\nEND:VCALENDAR"))
        #expect(PayloadParser.parse(encoded).kind == .event)
    }

    @Test func allDayEventUsesExclusiveEndDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 10))!
        let encoded = try #require(PayloadEncoder.event(EventDraft(title: "休日", start: day, end: day, isAllDay: true), calendar: calendar))
        #expect(encoded.contains("DTSTART;VALUE=DATE:20261024"))
        #expect(encoded.contains("DTEND;VALUE=DATE:20261025"))
    }

    @Test func eventRejectsEndBeforeStart() {
        let now = Date()
        #expect(PayloadEncoder.event(EventDraft(title: "x", start: now, end: now.addingTimeInterval(-60))) == nil)
    }
}
