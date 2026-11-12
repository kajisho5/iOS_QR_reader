import Observation

/// Carries a request to show a tab from outside the view tree (the Control Center control and the
/// Shortcuts action, via OpenScannerIntent) to RootView, which selects the tab and clears the request.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var pendingTab: AppTab?

    func open(_ tab: AppTab) {
        pendingTab = tab
    }
}
