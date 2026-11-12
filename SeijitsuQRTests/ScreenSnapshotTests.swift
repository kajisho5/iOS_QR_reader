import Foundation
import StoreKitTest
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import SeijitsuQR

/// Captures the main screens as PNGs when SNAPSHOT_DIR is set (CI passes it as TEST_RUNNER_SNAPSHOT_DIR).
/// With SNAPSHOT_PROFILE=duo (iPhone Duo simulator) it captures whichever display is active, at the scene's
/// real size, scale and traits with no size class overrides, and names the files after that display:
/// `screen-duo-<outer|inner>-<tab>.png`. With SNAPSHOT_PROFILE=appstore it captures the App Store screenshots
/// at the simulator's native resolution, each screen framed with its headline (StoreFrame):
/// `appstore-<iphone|ipad>-<NN>-<name>.png`, plus `iap-review.png` (the purchase screen without a frame) on iPhone.
/// Without SNAPSHOT_DIR the test does nothing.
@MainActor
@Suite(.serialized) struct ScreenSnapshotTests {
    @Test func captureAppStoreScreens() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment["SNAPSHOT_DIR"], environment["SNAPSHOT_PROFILE"] == "appstore" else { return }
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        // Loads the Pro product from the bundled StoreKit configuration so the purchase screen shows its price.
        let session = try? SKTestSession(configurationFileNamed: "Configuration")
        session?.disableDialogs = true
        session?.clearTransactions()
        session?.storefront = "JPN"
        session?.locale = Locale(identifier: "ja_JP")

        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let size = scene.coordinateSpace.bounds.size
        let scale = scene.screen.scale
        let device = scene.traitCollection.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let container = try SampleHistory.make()
        let defaults = try #require(UserDefaults(suiteName: "appstore-\(UUID().uuidString)"))
        let settings = AppSettings(defaults: defaults)
        let records = try container.mainContext.fetch(FetchDescriptor<ScanRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        let url = try #require(records.first(where: { $0.kind == .url }))
        let wifi = try #require(records.first(where: { $0.kind == .wifi }))
        let product = try #require(records.first(where: { $0.content == "4901234567894" }))

        func result(_ record: ScanRecord, title: String? = nil) -> some View {
            NavigationStack {
                ResultView(result: ScanResult(record: record))
                    .navigationTitle(title ?? record.kind.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        let store = ProStore()
        await store.loadProduct()
        store.screenshotDisplayPrice = "¥800"  // the Japanese App Store price (the simulator's sandbox is the US store)
        // Order and headlines: docs/design/appstore/SCREENSHOTS.md §3. The store listing is Japanese only.
        // iPad: the history opens with a record selected, so the list and its detail fill the screen; headlines are one line.
        let shots: [StoreShot] = device == "ipad" ? [
            StoreShot("history", HistoryView(initialSelection: url.persistentModelID).environment(store),
                      "開く前に、URL を全部見せる", "省略せずに全文を表示。まぎらわしい URL には開く前に注意を出します"),
            StoreShot("purchase", PaywallView().environment(store),
                      "広告なし。買い切りで、ずっと使える", "毎月の支払いはありません。読み取りは無料で、回数も無制限"),
            StoreShot("create", RootView(initialTab: .create),
                      "QR コードも、自分で作れる", "テキストと URL は無料。Wi-Fi・連絡先・イベントは Pro"),
        ] : [
            StoreShot("result-url", result(url),
                      "開く前に、\nURL を全部見せる", "省略せずに全文を表示。まぎらわしい URL には\n開く前に注意を出します"),
            StoreShot("history", RootView(initialTab: .history),
                      "読んだ中身を、\nどこにも送らない", "アプリは通信しません。登録も不要。\n履歴は Face ID などでロックできます"),
            StoreShot("purchase", PaywallView().environment(store),
                      "広告なし。\n買い切りで、ずっと使える", "毎月の支払いはありません。\n読み取りは無料で、回数も無制限"),
            StoreShot("result-product", result(product, title: L10n.resultProductTitle),
                      "バーコードの商品を、\nそのまま検索", "JAN・ISBN は、ボタンひとつで Web 検索。\n押すまで、どこにも送りません"),
            StoreShot("result-wifi", result(wifi),
                      "Wi-Fi の QR から、\nそのまま接続", "パスワードは伏せたまま確認できます"),
            StoreShot("create", RootView(initialTab: .create),
                      "QR コードも、\n自分で作れる", "テキストと URL は無料。\nWi-Fi・連絡先・イベントは Pro"),
        ]
        for (index, shot) in shots.enumerated() {
            let screen = try await render(shot.view.environment(settings).modelContainer(container), size: size, scale: scale, in: scene)
            // The In-App Purchase review screenshot is the purchase screen itself, without a headline.
            if device == "iphone", shot.name == "purchase" {
                try #require(screen.pngData()).write(to: URL(fileURLWithPath: directory).appendingPathComponent("iap-review.png"))
            }
            let frame = StoreFrame(headline: shot.headline, subline: shot.subline, screen: screen,
                                   device: device == "ipad" ? .ipad : .iphone, size: size)
            let image = try await render(frame, size: size, scale: scale, in: scene)
            let file = String(format: "appstore-%@-%02d-%@.png", device, index + 1, shot.name)
            try #require(image.pngData()).write(to: URL(fileURLWithPath: directory).appendingPathComponent(file))
        }
        try "device: \(device) size: \(size) scale: \(scale) sandbox price: \(store.product?.displayPrice ?? "none")"
            .write(toFile: directory + "/diagnostics-appstore-\(device).txt", atomically: true, encoding: .utf8)
    }

    @Test func captureScreens() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment["SNAPSHOT_DIR"], environment["SNAPSHOT_PROFILE"] == "duo" else { return }
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let bounds = scene.coordinateSpace.bounds.size
        let traits = scene.traitCollection
        let display = traits.horizontalSizeClass == .regular ? "inner" : "outer"
        try [
            "scene bounds: \(bounds)",
            "screen bounds: \(scene.screen.bounds.size) scale: \(scene.screen.scale)",
            "size classes: h=\(traits.horizontalSizeClass.rawValue) v=\(traits.verticalSizeClass.rawValue)",
            "safe area: \(scene.keyWindow?.safeAreaInsets ?? .zero)",
            "orientation: \(scene.effectiveGeometry.interfaceOrientation.rawValue)",
        ].joined(separator: "\n").write(toFile: directory + "/diagnostics-duo-\(display).txt", atomically: true, encoding: .utf8)

        let container = try SampleHistory.make()
        let defaults = try #require(UserDefaults(suiteName: "snapshots-\(UUID().uuidString)"))
        let settings = AppSettings(defaults: defaults)

        for tab in AppTab.allCases {
            let view = RootView(initialTab: tab)
                .environment(settings)
                .modelContainer(container)
            let image = try await render(view, size: bounds, scale: scene.screen.scale, in: scene)
            let data = try #require(image.pngData())
            try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("screen-duo-\(display)-\(tab.snapshotName).png"))
        }
    }

    private func render(_ view: some View, size: CGSize, scale: CGFloat, in scene: UIWindowScene) async throws -> UIImage {
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = UIHostingController(rootView: view)
        window.isHidden = false
        // Let SwiftUI resolve queries and layout.
        for _ in 0..<6 {
            try await Task.sleep(for: .milliseconds(250))
            window.layoutIfNeeded()
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        return image
    }
}

/// One App Store screenshot: the screen to capture and the headline drawn above it.
@MainActor
private struct StoreShot {
    let name: String
    let view: AnyView
    let headline: String
    let subline: String

    init(_ name: String, _ view: some View, _ headline: String, _ subline: String) {
        self.name = name
        self.view = AnyView(view)
        self.headline = headline
        self.subline = subline
    }
}

private extension AppTab {
    var snapshotName: String {
        switch self {
        case .scan: "scan"
        case .history: "history"
        case .create: "create"
        case .settings: "settings"
        }
    }
}

/// Fictional sample history (no real people, networks or numbers).
@MainActor
private enum SampleHistory {
    static func make() throws -> ModelContainer {
        let container = try HistoryContainer.make(inMemory: true)
        let recorder = HistoryRecorder(context: container.mainContext)
        let now = Date.now
        let drafts: [RecordDraft] = [
            RecordDraft(content: "https://www.example.com/campaign/2026/autumn?ref=store-1234", kind: .url, symbology: .qr, source: .camera, createdAt: now.addingTimeInterval(-300)),
            RecordDraft(content: "WIFI:T:WPA;S:Sample-Cafe_5G;P:example-pass;;", kind: .wifi, symbology: .qr, source: .camera, createdAt: now.addingTimeInterval(-900)),
            RecordDraft(content: "4901234567894", kind: .text, symbology: .ean13, source: .camera, createdAt: now.addingTimeInterval(-1800)),
            RecordDraft(content: "BEGIN:VCARD\nVERSION:3.0\nN:見本;太郎;;;\nFN:見本 太郎\nORG:見本商事\nEND:VCARD", kind: .contact, symbology: .qr, source: .created, createdAt: now.addingTimeInterval(-90_000)),
            RecordDraft(content: "tel:0312345678", kind: .phone, symbology: .qr, source: .camera, createdAt: now.addingTimeInterval(-95_000)),
            RecordDraft(content: "https://example.org/menu/lunch", kind: .url, symbology: .qr, source: .photo, createdAt: now.addingTimeInterval(-180_000)),
            RecordDraft(content: "9784000000000", kind: .text, symbology: .ean13, source: .camera, createdAt: now.addingTimeInterval(-260_000)),
        ]
        for draft in drafts {
            try recorder.record(draft, isPro: true)
        }
        return container
    }
}
