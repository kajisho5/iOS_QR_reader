import SwiftUI

struct RootView: View {
    @State private var selection: AppTab
    @State private var store = ProStore()
    @State private var isPaywallPresented = false
    @State private var isHistorySearchPresented = false
    @State private var historyLock = HistoryLock()
    /// Pro is known only after the entitlements are read; until then nothing is saved on the app's own initiative
    /// (a free-plan save trims the history to 30 records).
    @State private var hasCheckedEntitlements = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    private let router = AppRouter.shared

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
        .environment(historyLock)
        .onChange(of: scenePhase) { _, phase in
            // The history locks again whenever the app leaves the screen.
            if phase == .background {
                historyLock.lock()
                // The favorites may have changed while the app was open.
                updateWidget()
            } else if phase == .active, hasCheckedEntitlements {
                importSharedScans()
            }
        }
        .onChange(of: store.isPro) { updateWidget() }
        .onOpenURL { url in
            // From the home screen widget: seijitsuqr://pro opens the purchase screen.
            if url.scheme == "seijitsuqr", url.host == "pro", !store.isPro { isPaywallPresented = true }
        }
        // The "QRスキャン" control or Shortcuts action opened the app (OpenScannerIntent).
        .onChange(of: router.pendingTab, initial: true) { _, tab in
            guard let tab else { return }
            selection = tab
            router.pendingTab = nil
        }
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
        .task {
            await store.refreshEntitlements()
            hasCheckedEntitlements = true
            importSharedScans()
            updateWidget()
            await store.loadProduct()
        }
    }

    /// Codes read in the share sheet since the app was last open (docs/DESIGN_1.1.md §5, E).
    private func importSharedScans() {
        PendingScanImporter.importAll(context: modelContext, isPro: store.isPro, autosave: settings.isAutosaveEnabled)
    }

    private func updateWidget() {
        WidgetSnapshotWriter.update(context: modelContext, isPro: store.isPro)
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
