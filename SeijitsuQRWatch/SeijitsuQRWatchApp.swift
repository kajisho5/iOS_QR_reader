import SwiftUI
import WatchConnectivity

/// Apple Watch app (docs/DESIGN_1.2.md §8, K; docs/design/28_apple_watch.svg): the favorites chosen on the
/// iPhone, each shown full screen on white. The watch does not scan (it has no camera).
@main
struct SeijitsuQRWatchApp: App {
    @State private var store = WatchCodeStore()

    var body: some Scene {
        WindowGroup {
            WatchCodeList(store: store)
        }
    }
}

/// Receives the codes from the iPhone and keeps the last list on the watch.
@MainActor
@Observable
final class WatchCodeStore: NSObject, WCSessionDelegate {
    private(set) var codes: [WatchCode] = []
    private static let savedKey = "watch.codes"

    override init() {
        super.init()
        // App Store screenshots (appstore-screenshots workflow): fictional sample codes, no connection to a phone.
        if ProcessInfo.processInfo.arguments.contains("-StoreScreenshots") {
            codes = Self.samples
            return
        }
        if let data = UserDefaults.standard.data(forKey: Self.savedKey) { codes = WatchCodes.decode(data) }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private static var samples: [WatchCode] {
        [("SampleWiFi", "Seijitsu-Guest", "Wi-Fi"), ("SampleCard", "会員証（誠実書店）", "URL")].compactMap { name, title, kind in
            guard let png = UIImage(named: name)?.pngData() else { return nil }
            return WatchCode(id: UUID(), title: title, kindTitle: kind, image: png)
        }
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context[WatchCodes.contextKey] as? Data else { return }
        codes = WatchCodes.decode(data)
        UserDefaults.standard.set(data, forKey: Self.savedKey)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let context = session.receivedApplicationContext
        let data = context[WatchCodes.contextKey] as? Data
        Task { @MainActor in if let data { self.apply([WatchCodes.contextKey: data]) } }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[WatchCodes.contextKey] as? Data
        Task { @MainActor in if let data { self.apply([WatchCodes.contextKey: data]) } }
    }
}

struct WatchCodeList: View {
    let store: WatchCodeStore
    /// The screenshot of one code opens it directly.
    @State private var opened: WatchCode?

    var body: some View {
        NavigationStack {
            Group {
                if store.codes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.title)
                        Text("iPhone の誠実QRリーダーの設定で、表示するお気に入りを選んでください。")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(store.codes) { code in
                        NavigationLink {
                            WatchCodeView(code: code)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(code.title).font(.headline).lineLimit(2)
                                Text(code.kindTitle).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("QR")
            .navigationDestination(item: $opened) { WatchCodeView(code: $0) }
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-StoreScreenshotCode") { opened = store.codes.first }
            }
        }
    }
}

/// One code, as large as the screen allows, on white so a scanner can read it.
struct WatchCodeView: View {
    let code: WatchCode

    var body: some View {
        VStack(spacing: 4) {
            if let image = UIImage(data: code.image) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(code.title)
            }
            Text(code.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }
}
