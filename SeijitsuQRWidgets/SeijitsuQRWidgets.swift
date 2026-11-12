import AppIntents
import SwiftUI
import WidgetKit

/// The widget extension (docs/DESIGN_1.1.md §3–4). Today it holds the "QRスキャン" control (iOS 18 and later);
/// the home screen widgets (B) are added here later.
@main
struct SeijitsuQRWidgets: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            ScanControl()
        }
    }
}

/// "QRスキャン" for Control Center, the Lock Screen and the Action button. Tapping it opens the app on the scan tab;
/// the camera is already being prepared at launch (CaptureEngine.prewarm).
@available(iOS 18.0, *)
struct ScanControl: ControlWidget {
    static let kind = "com.seventhwell.seijitsuqr.control.scan"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenScannerIntent(target: .scanner)) {
                Label("QRスキャン", systemImage: "qrcode.viewfinder")
            }
        }
        .displayName("QRスキャン")
        .description("誠実QRリーダーを開いて、すぐにスキャンを始めます。")
    }
}
