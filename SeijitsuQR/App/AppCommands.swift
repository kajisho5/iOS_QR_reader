import SwiftUI

/// Menu commands. On iPad with a hardware keyboard they appear in the system's shortcut list
/// (and the menu bar on iPadOS versions that have one).
struct AppCommands: Commands {
    @FocusedValue(\.appCommandActions) private var actions

    var body: some Commands {
        CommandMenu(L10n.menuGo) {
            ForEach(Array(AppTab.allCases.enumerated()), id: \.element) { index, tab in
                Button(tab.title) { actions?.selectTab(tab) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
                    .disabled(actions == nil)
            }
            Divider()
            Button(L10n.menuSearchHistory) { actions?.searchHistory() }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(actions == nil)
        }
    }
}

extension AppTab {
    var title: String {
        switch self {
        case .scan: L10n.tabScan
        case .history: L10n.tabHistory
        case .create: L10n.tabCreate
        case .settings: L10n.tabSettings
        }
    }
}
