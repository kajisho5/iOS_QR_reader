import AppIntents

/// "QRをスキャン" in the Shortcuts app, Siri and the Action button (iOS 17 and later). On iOS 18 and later the
/// same intent also backs the Control Center and Lock Screen control in the widget extension.
struct SeijitsuQRShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenScannerIntent(target: .scanner),
            phrases: [
                "\(.applicationName)でスキャン",
                "\(.applicationName)でQRを読む",
            ],
            shortTitle: "QRをスキャン",
            systemImageName: "qrcode.viewfinder"
        )
    }
}
