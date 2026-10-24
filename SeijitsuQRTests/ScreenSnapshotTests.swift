import Foundation
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import SeijitsuQR

/// Captures the main screens as PNGs when SNAPSHOT_DIR is set (CI passes it as TEST_RUNNER_SNAPSHOT_DIR).
/// With SNAPSHOT_PROFILE=duo (iPhone Duo simulator) it captures whichever display is active, at the scene's
/// real size, scale and traits with no size class overrides, and names the files after that display:
/// `screen-duo-<outer|inner>-<tab>.png`. Without SNAPSHOT_DIR the test does nothing.
@MainActor
@Suite(.serialized) struct ScreenSnapshotTests {
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
        ]
        for draft in drafts {
            try recorder.record(draft, isPro: true)
        }
        return container
    }
}
