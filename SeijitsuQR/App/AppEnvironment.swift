import SwiftUI

enum AppTab: Hashable {
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
}
