import SwiftUI

struct RootView: View {
    @State private var selection: AppTab
    @State private var store = ProStore()
    @State private var isPaywallPresented = false
    @State private var isHistorySearchPresented = false

    init(initialTab: AppTab = .scan) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            ScannerView()
                .tabItem { Label(L10n.tabScan, systemImage: "qrcode.viewfinder") }
                .tag(AppTab.scan)
            HistoryView()
                .tabItem { Label(L10n.tabHistory, systemImage: "clock") }
                .tag(AppTab.history)
            CreateView()
                .tabItem { Label(L10n.tabCreate, systemImage: "plus.square") }
                .tag(AppTab.create)
            SettingsView()
                .tabItem { Label(L10n.tabSettings, systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .environment(store)
        .environment(\.isProUnlocked, store.isPro)
        .environment(\.selectTab, SelectTabAction { [binding = $selection] in binding.wrappedValue = $0 })
        .environment(\.requestPro, RequestProAction { [binding = $isPaywallPresented] _ in binding.wrappedValue = true })
        .environment(\.isHistorySearchPresented, $isHistorySearchPresented)
        .focusedSceneValue(\.appCommandActions, commandActions)
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView()
                .environment(store)
                .presentationDragIndicator(.visible)
        }
        .task { await store.start() }
    }

    private var commandActions: AppCommandActions {
        AppCommandActions(
            selectTab: { [binding = $selection] in binding.wrappedValue = $0 },
            searchHistory: { [selection = $selection, search = $isHistorySearchPresented] in
                selection.wrappedValue = .history
                search.wrappedValue = true
            }
        )
    }
}
