import Foundation
import Testing
@testable import SeijitsuQR

/// Every catalog key must resolve to a Japanese string in the app bundle (no raw keys on screen).
struct LocalizationTests {
    @Test(arguments: L10n.allKeys)
    func keyResolves(_ key: String) {
        let value = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
        #expect(value != key, "missing translation for \(key)")
        #expect(!value.isEmpty)
    }

    @Test func formattedStringsInsertArguments() {
        #expect(L10n.scanDetectedAnnouncement("URL").contains("URL"))
    }
}
