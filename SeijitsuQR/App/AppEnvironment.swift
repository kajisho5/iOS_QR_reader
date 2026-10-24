import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case scan
    case history
    case create
    case settings
}

/// Features that need the one-time Pro purchase.
enum ProFeature: Hashable, Sendable {
    case unlimitedHistory
    case allCodeTypes
    case csvExport
}

/// Switches the selected tab (e.g. "スキャンを始める" on the empty history screen).
struct SelectTabAction: Sendable {
    var handler: @MainActor @Sendable (AppTab) -> Void = { _ in }
    @MainActor func callAsFunction(_ tab: AppTab) { handler(tab) }
}

/// Opens the purchase screen. Only ever triggered by the user tapping a locked feature.
struct RequestProAction: Sendable {
    var handler: @MainActor @Sendable (ProFeature) -> Void = { _ in }
    @MainActor func callAsFunction(_ feature: ProFeature) { handler(feature) }
}

extension EnvironmentValues {
    /// Whether the one-time Pro purchase is active. Set from StoreKit in the purchase step;
    /// until then the free plan applies everywhere.
    @Entry var isProUnlocked: Bool = false
    @Entry var selectTab = SelectTabAction()
    @Entry var requestPro = RequestProAction()
    /// Activates the history search field (hardware keyboard: ⌘F).
    @Entry var isHistorySearchPresented: Binding<Bool> = .constant(false)
}

/// Actions behind the app's menu commands (hardware keyboard shortcuts on iPad).
struct AppCommandActions {
    var selectTab: @MainActor (AppTab) -> Void
    var searchHistory: @MainActor () -> Void
}

private struct AppCommandActionsKey: FocusedValueKey {
    typealias Value = AppCommandActions
}

extension FocusedValues {
    var appCommandActions: AppCommandActions? {
        get { self[AppCommandActionsKey.self] }
        set { self[AppCommandActionsKey.self] = newValue }
    }
}
