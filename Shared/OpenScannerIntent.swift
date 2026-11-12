import AppIntents

/// Opens the app on the scan tab (docs/DESIGN_1.1.md §3, D). Shared by the app and the widget extension:
/// the control in the extension names this intent, and iOS runs it in the app because it is an OpenIntent.
struct OpenScannerIntent: OpenIntent {
    static let title: LocalizedStringResource = "QRをスキャン"
    static let description = IntentDescription("誠実QRリーダーを開いて、すぐにスキャンを始めます。")

    @Parameter(title: "開く画面")
    var target: AppScreen

    init() {}

    init(target: AppScreen) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        AppRouter.shared.open(target.tab)
        #endif
        return .result()
    }
}

/// The screens the app can be opened on from outside (today only the scanner).
enum AppScreen: String, AppEnum {
    case scanner

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "画面"
    static let caseDisplayRepresentations: [AppScreen: DisplayRepresentation] = [.scanner: "スキャン"]
}

#if !WIDGET_EXTENSION
extension AppScreen {
    var tab: AppTab {
        switch self {
        case .scanner: .scan
        }
    }
}
#endif
