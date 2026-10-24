import Foundation

/// Values to replace before release. Listed in README ("差し替えが必要な定数").
enum AppConstants {
    /// Non-consumable in-app purchase registered in App Store Connect.
    static let proProductID = "com.example.seijitsuqr.pro"
    // These literals are fixed, valid URLs, so force-unwrapping cannot fail at runtime.
    static let privacyPolicyURL = URL(string: "https://example.com/seijitsuqr/privacy")!
    static let termsOfUseURL = URL(string: "https://example.com/seijitsuqr/terms")!
}
