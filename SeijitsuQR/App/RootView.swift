import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem { Label(L10n.tabScan, systemImage: "qrcode.viewfinder") }
            PlaceholderView(systemImage: "clock")
                .tabItem { Label(L10n.tabHistory, systemImage: "clock") }
            PlaceholderView(systemImage: "plus.square")
                .tabItem { Label(L10n.tabCreate, systemImage: "plus.square") }
            PlaceholderView(systemImage: "gearshape")
                .tabItem { Label(L10n.tabSettings, systemImage: "gearshape") }
        }
    }
}

/// Stands in for tabs that are built in later implementation steps.
private struct PlaceholderView: View {
    let systemImage: String

    var body: some View {
        ContentUnavailableView(L10n.placeholderTitle, systemImage: systemImage, description: Text(L10n.placeholderMessage))
    }
}
