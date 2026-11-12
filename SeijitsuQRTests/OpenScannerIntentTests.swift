import Testing
@testable import SeijitsuQR

/// The "QRスキャン" control and Shortcuts action open the app on the scan tab (docs/DESIGN_1.1.md §3, D).
@MainActor
struct OpenScannerIntentTests {
    @Test func performAsksForTheScanTab() async throws {
        let router = AppRouter.shared
        router.pendingTab = .history
        _ = try await OpenScannerIntent(target: .scanner).perform()
        #expect(router.pendingTab == .scan)
        router.pendingTab = nil
    }

    @Test func scannerScreenIsTheScanTab() {
        #expect(AppScreen.scanner.tab == .scan)
    }
}
