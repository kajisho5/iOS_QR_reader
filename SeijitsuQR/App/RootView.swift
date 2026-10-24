import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .scan

    var body: some View {
        TabView(selection: $selection) {
            ScannerView()
                .tabItem { Label(L10n.tabScan, systemImage: "qrcode.viewfinder") }
                .tag(AppTab.scan)
            HistoryView()
                .tabItem { Label(L10n.tabHistory, systemImage: "clock") }
                .tag(AppTab.history)
            PlaceholderView(systemImage: "plus.square")
                .tabItem { Label(L10n.tabCreate, systemImage: "plus.square") }
                .tag(AppTab.create)
            PlaceholderView(systemImage: "gearshape")
                .tabItem { Label(L10n.tabSettings, systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .environment(\.selectTab, SelectTabAction { [binding = $selection] in binding.wrappedValue = $0 })
    }
}

/// Stands in for tabs that are built in later implementation steps.
private struct PlaceholderView: View {
    let systemImage: String

    var body: some View {
        ContentUnavailableView(L10n.placeholderTitle, systemImage: systemImage, description: Text(L10n.placeholderMessage))
    }
}
