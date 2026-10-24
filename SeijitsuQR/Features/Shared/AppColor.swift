import SwiftUI

/// Custom colors from the asset catalog (each defines Any / Dark / High Contrast variants).
/// Backgrounds and text use system semantic colors instead.
enum AppColor {
    static let accentFill = Color("AccentFill")
    static let accentSoft = Color("AccentSoft")
    static let accentOnSoft = Color("AccentOnSoft")
    static let favoriteTint = Color("FavoriteTint")
    static let favoriteFill = Color("FavoriteFill")
    /// Accent used over the camera preview (always dark behind it).
    static let accentOnCamera = Color("AccentOnCamera")

    static func kind(_ kind: PayloadKind) -> Color {
        switch kind {
        case .url: Color("KindURL")
        case .wifi: Color("KindWiFi")
        case .contact: Color("KindContact")
        case .email: Color("KindEmail")
        case .phone: Color("KindPhone")
        case .sms: Color("KindSMS")
        case .geo: Color("KindGeo")
        case .event: Color("KindEvent")
        case .text: Color("KindText")
        }
    }
}
