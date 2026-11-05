import Foundation
import Testing
@testable import SeijitsuQR

struct ActionURLsTests {
    @Test func mailEncodesSubjectAndBody() throws {
        let url = try #require(ActionURLs.mail(EmailMessage(address: "a@example.com", subject: "件名 A", body: "x&y")))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "mailto")
        #expect(components.path == "a@example.com")
        #expect(components.queryItems?.first(where: { $0.name == "subject" })?.value == "件名 A")
        #expect(components.queryItems?.first(where: { $0.name == "body" })?.value == "x&y")
    }

    @Test func phoneStripsEverythingButDialCharacters() {
        #expect(ActionURLs.phone("+81 (3) 1234-5678")?.absoluteString == "tel:+81312345678")
        #expect(ActionURLs.phone("call me") == nil)
    }

    @Test func smsUsesNumberOnly() {
        #expect(ActionURLs.sms(SMSMessage(number: "090-0000-0000", body: "hi"))?.absoluteString == "sms:09000000000")
    }

    @Test func mapsCarriesCoordinateAndQuery() throws {
        let url = try #require(ActionURLs.maps(GeoPoint(latitude: 35.68124, longitude: 139.76712, query: "東京駅")))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.host == "maps.apple.com")
        #expect(items.first(where: { $0.name == "ll" })?.value == "35.68124,139.76712")
        #expect(items.first(where: { $0.name == "q" })?.value == "東京駅")
    }

    // MARK: Product codes (docs/DESIGN_1.1.md §2.5)

    @Test(arguments: SearchEngine.allCases)
    func webSearchCarriesOnlyTheQuery(_ engine: SearchEngine) throws {
        let url = try #require(engine.url(searching: "ISBN 9784101010014"))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "https")
        #expect(components.queryItems?.count == 1)
        #expect(components.queryItems?.first?.value == "ISBN 9784101010014")
    }

    @Test func searchHosts() {
        #expect(SearchEngine.google.url(searching: "4901234567894")?.host == "www.google.com")
        #expect(SearchEngine.yahooJapan.url(searching: "4901234567894")?.absoluteString == "https://search.yahoo.co.jp/search?p=4901234567894")
        #expect(SearchEngine.duckDuckGo.url(searching: "4901234567894")?.host == "duckduckgo.com")
        #expect(SearchEngine.bing.url(searching: "4901234567894")?.host == "www.bing.com")
    }

    @Test func productCodesAndBooks() {
        #expect(ProductCode.isProductCode(.ean13) && ProductCode.isProductCode(.ean8) && ProductCode.isProductCode(.upce))
        #expect(!ProductCode.isProductCode(.qr) && !ProductCode.isProductCode(.code128))
        #expect(ProductCode.isISBN("9784101010014", symbology: .ean13))
        #expect(!ProductCode.isISBN("9784101010015", symbology: .ean13))  // wrong check digit
        #expect(!ProductCode.isISBN("4901234567894", symbology: .ean13))  // not a book
        #expect(!ProductCode.isISBN("9784101010014", symbology: .code128))
    }
}
