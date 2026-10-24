import Foundation
import Testing
@testable import SeijitsuQR

struct PayloadParserTests {
    // MARK: URL

    @Test func httpsURLIsALink() {
        let payload = PayloadParser.parse("https://www.example.co.jp/campaign?utm_source=qr&ref=1")
        guard case .url(let url) = payload else { Issue.record("expected url, got \(payload)"); return }
        #expect(url.host == "www.example.co.jp")
    }

    @Test func uppercaseSchemeIsALink() {
        #expect(PayloadParser.parse("HTTP://EXAMPLE.COM").kind == .url)
    }

    @Test(arguments: ["javascript:alert(1)", "myapp://open?id=1", "www.example.com", "ftp://example.com/file", "https://"])
    func nonWebSchemesStayText(_ input: String) {
        #expect(PayloadParser.parse(input) == .text(input))
    }

    @Test func surroundingWhitespaceIsIgnoredForDetection() {
        #expect(PayloadParser.parse("  https://example.com/a \n").kind == .url)
    }

    // MARK: Wi-Fi

    @Test func wpaNetwork() {
        let payload = PayloadParser.parse("WIFI:T:WPA;S:Seijitsu-Cafe_5G;P:pass word;H:false;;")
        #expect(payload == .wifi(WiFiNetwork(ssid: "Seijitsu-Cafe_5G", password: "pass word", security: .wpa, isHidden: false)))
    }

    @Test func wifiFieldsInAnyOrderWithEscapes() {
        let payload = PayloadParser.parse(#"WIFI:S:My\;Net\:1;P:a\\b\,c;T:SAE;H:true;;"#)
        #expect(payload == .wifi(WiFiNetwork(ssid: "My;Net:1", password: #"a\b,c"#, security: .wpa, isHidden: true)))
    }

    @Test func openNetworkHasNoPassword() {
        let payload = PayloadParser.parse("WIFI:T:nopass;S:Guest;;")
        #expect(payload == .wifi(WiFiNetwork(ssid: "Guest", password: nil, security: .open, isHidden: false)))
    }

    @Test func wepNetwork() {
        guard case .wifi(let network) = PayloadParser.parse("WIFI:T:WEP;S:Old;P:12345;;") else { Issue.record("expected wifi"); return }
        #expect(network.security == .wep)
        #expect(network.password == "12345")
    }

    @Test func wifiWithoutSSIDIsText() {
        #expect(PayloadParser.parse("WIFI:T:WPA;P:x;;").kind == .text)
    }

    // MARK: Contacts

    @Test func vCard30WithFoldingAndMultipleValues() {
        let vcard = [
            "BEGIN:VCARD", "VERSION:3.0", "N:山田;太郎;;;", "FN:山田 太郎",
            "ORG:誠実商事;営業部", "TITLE:部長", "TEL;TYPE=WORK:03-1234-5678", "TEL;TYPE=CELL:090-0000-0000",
            "EMAIL:taro@example.co.jp", "ADR;TYPE=WORK:;;丸の内1-1;千代田区;東京都;100-0005;日本",
            "NOTE:一行目\\n二行目が", " 折り返し", "END:VCARD",
        ].joined(separator: "\r\n")
        guard case .contact(let card) = PayloadParser.parse(vcard) else { Issue.record("expected contact"); return }
        #expect(card.formattedName == "山田 太郎")
        #expect(card.familyName == "山田")
        #expect(card.givenName == "太郎")
        #expect(card.organization == "誠実商事 営業部")
        #expect(card.jobTitle == "部長")
        #expect(card.phoneNumbers == ["03-1234-5678", "090-0000-0000"])
        #expect(card.emails == ["taro@example.co.jp"])
        #expect(card.addresses == ["100-0005 日本 東京都 千代田区 丸の内1-1"])
        #expect(card.note == "一行目\n二行目が折り返し")
    }

    @Test func vCard21QuotedPrintable() {
        let vcard = "BEGIN:VCARD\nVERSION:2.1\nFN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E5=B1=B1=E7=94=B0\nEND:VCARD"
        guard case .contact(let card) = PayloadParser.parse(vcard) else { Issue.record("expected contact"); return }
        #expect(card.formattedName == "山田")
    }

    @Test func meCard() {
        let payload = PayloadParser.parse("MECARD:N:山田,太郎;SOUND:ヤマダ,タロウ;TEL:0312345678;EMAIL:taro@example.co.jp;NOTE:a\\;b;;")
        guard case .contact(let card) = payload else { Issue.record("expected contact"); return }
        #expect(card.familyName == "山田")
        #expect(card.givenName == "太郎")
        #expect(card.phoneticName == "ヤマダ タロウ")
        #expect(card.phoneNumbers == ["0312345678"])
        #expect(card.note == "a;b")
        #expect(card.displayName == "山田 太郎")
    }

    @Test func emptyVCardIsText() {
        #expect(PayloadParser.parse("BEGIN:VCARD\nVERSION:3.0\nEND:VCARD").kind == .text)
    }

    // MARK: Email / phone / SMS / geo / event

    @Test func mailtoWithQuery() {
        let payload = PayloadParser.parse("mailto:info@example.co.jp?subject=%E3%81%8A%E5%95%8F%E3%81%84%E5%90%88%E3%82%8F%E3%81%9B&body=Hello+there")
        #expect(payload == .email(EmailMessage(address: "info@example.co.jp", subject: "お問い合わせ", body: "Hello there")))
    }

    @Test func matmsg() {
        let payload = PayloadParser.parse("MATMSG:TO:a@example.com;SUB:件名;BODY:本文;;")
        #expect(payload == .email(EmailMessage(address: "a@example.com", subject: "件名", body: "本文")))
    }

    @Test func tel() {
        #expect(PayloadParser.parse("tel:+81-3-1234-5678") == .phone("+81-3-1234-5678"))
    }

    @Test func smsto() {
        #expect(PayloadParser.parse("SMSTO:09000000000:こんにちは") == .sms(SMSMessage(number: "09000000000", body: "こんにちは")))
    }

    @Test func smsURIWithBody() {
        #expect(PayloadParser.parse("sms:+819000000000?body=Hi%20there") == .sms(SMSMessage(number: "+819000000000", body: "Hi there")))
    }

    @Test func geoWithQuery() {
        let payload = PayloadParser.parse("geo:35.68124,139.76712?q=Tokyo+Station")
        #expect(payload == .geo(GeoPoint(latitude: 35.68124, longitude: 139.76712, query: "Tokyo Station")))
    }

    @Test(arguments: ["geo:91,0", "geo:0,181", "geo:abc,def", "geo:35.6"])
    func invalidGeoIsText(_ input: String) {
        #expect(PayloadParser.parse(input).kind == .text)
    }

    @Test func calendarEvent() {
        #expect(PayloadParser.parse("BEGIN:VEVENT\nSUMMARY:会議\nEND:VEVENT").kind == .event)
    }

    @Test func plainTextKeepsOriginalString() {
        #expect(PayloadParser.parse(" 4901234567894 ") == .text(" 4901234567894 "))
    }
}
