import Foundation
import Testing
@testable import SeijitsuQR

/// Mail, phone, SMS and location codes (docs/DESIGN_1.2.md §1, L): what is written, and that the parser reads it back.
struct PayloadEncoderMoreKindsTests {
    @Test func emailRoundTripsThroughTheParser() throws {
        let encoded = try #require(PayloadEncoder.email(EmailDraft(address: "info@example.co.jp", subject: "資料のご請求 & 見積", body: "1部お願いします。\n住所：東京")))
        #expect(encoded.hasPrefix("mailto:info@example.co.jp?subject="))
        #expect(!encoded.contains(" "))
        #expect(PayloadParser.parse(encoded) == .email(EmailMessage(address: "info@example.co.jp", subject: "資料のご請求 & 見積", body: "1部お願いします。\n住所：東京")))
    }

    @Test func emailNeedsAnAddress() {
        #expect(PayloadEncoder.email(EmailDraft(address: "", subject: "件名")) == nil)
        #expect(PayloadEncoder.email(EmailDraft(address: "not-an-address")) == nil)
        #expect(PayloadEncoder.email(EmailDraft(address: "a@example.com")) == "mailto:a@example.com")
    }

    @Test func phoneKeepsOnlyDialableCharacters() {
        #expect(PayloadEncoder.phone("03-1234-5678") == "tel:0312345678")
        #expect(PayloadEncoder.phone("+81 (3) 1234 5678") == "tel:+81312345678")
        #expect(PayloadEncoder.phone("電話") == nil)
        #expect(PayloadParser.parse("tel:0312345678") == .phone("0312345678"))
    }

    @Test func smsRoundTripsThroughTheParser() throws {
        let encoded = try #require(PayloadEncoder.sms(SMSDraft(number: "090-1234-5678", body: "着きました")))
        #expect(encoded == "SMSTO:09012345678:着きました")
        #expect(PayloadParser.parse(encoded) == .sms(SMSMessage(number: "09012345678", body: "着きました")))
        #expect(PayloadEncoder.sms(SMSDraft(number: "", body: "x")) == nil)
    }

    @Test func geoRoundTripsThroughTheParser() throws {
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "35.68124", longitude: "139.76712")) == "geo:35.68124,139.76712")
        let named = try #require(PayloadEncoder.geo(GeoDraft(latitude: " 35.681240 ", longitude: "139.767120", name: "誠実商事 (本社)")))
        #expect(PayloadParser.parse(named) == .geo(GeoPoint(latitude: 35.68124, longitude: 139.76712, query: "35.68124,139.76712(誠実商事 （本社）)")))
    }

    @Test func geoRejectsCoordinatesOutOfRange() {
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "91", longitude: "0")) == nil)
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "0", longitude: "-180.5")) == nil)
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "1e2", longitude: "0")) == nil)
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "", longitude: "0")) == nil)
        #expect(PayloadEncoder.geo(GeoDraft(latitude: "-0.0000001", longitude: "0")) == "geo:0,0")
    }

    @Test func everyNewKindNeedsPro() {
        for kind in [CreateKind.email, .phone, .sms, .geo] {
            #expect(kind.requiresPro)
        }
        #expect(!CreateKind.text.requiresPro)
        #expect(!CreateKind.url.requiresPro)
    }
}
