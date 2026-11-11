import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var store
    @Environment(\.requestPro) private var requestPro
    @State private var notice: ProStore.Notice?
    @Environment(HistoryLock.self) private var historyLock: HistoryLock?
    @State private var isLockUnavailable = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppColor.accentFill)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "qrcode").foregroundStyle(.white).font(.title3.weight(.semibold))
                            }
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.settingsProName).font(.headline)
                            Text(proStatus).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        if store.isPro {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                        } else {
                            Button(L10n.settingsProBuy) { requestPro(.unlimitedHistory) }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColor.accentFill)
                                .buttonBorderShape(.capsule)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    Button(L10n.settingsProRestore) {
                        Task { notice = await store.restore() }
                    }
                    .disabled(store.isWorking)
                } header: {
                    Text(L10n.settingsProHeader)
                } footer: {
                    Text(L10n.settingsProFooter)
                }

                Section(L10n.settingsScanHeader) {
                    Toggle(L10n.settingsScanSound, isOn: $settings.isSoundEnabled)
                    Toggle(L10n.settingsScanHaptics, isOn: $settings.isHapticsEnabled)
                    NavigationLink {
                        SearchEnginePicker()
                    } label: {
                        LabeledContent(L10n.settingsScanSearchEngine, value: settings.searchEngine.title)
                    }
                }
                .tint(AppColor.accentFill)

                Section {
                    Toggle(L10n.settingsHistoryAutosave, isOn: $settings.isAutosaveEnabled)
                        .tint(AppColor.accentFill)
                    Toggle(L10n.settingsHistoryLock(HistoryLock.methodName), isOn: historyLockBinding)
                        .tint(AppColor.accentFill)
                } header: {
                    Text(L10n.settingsHistoryHeader)
                } footer: {
                    Text(L10n.settingsHistoryFooter + "\n" + L10n.settingsHistoryLockFooter)
                }
                .alert(L10n.historyLockUnavailableTitle, isPresented: $isLockUnavailable) {
                    Button(L10n.commonClose, role: .cancel) {}
                } message: {
                    Text(L10n.historyLockUnavailableMessage)
                }

                Section {
                    Link(destination: AppConstants.privacyPolicyURL) {
                        LabeledContent(L10n.settingsAboutPrivacy) {
                            Image(systemName: "arrow.up.right.square").foregroundStyle(.secondary).accessibilityHidden(true)
                        }
                    }
                    Link(destination: AppConstants.termsOfUseURL) {
                        LabeledContent(L10n.settingsAboutTerms) {
                            Image(systemName: "arrow.up.right.square").foregroundStyle(.secondary).accessibilityHidden(true)
                        }
                    }
                    LabeledContent(L10n.settingsAboutVersion, value: appVersion)
                } header: {
                    Text(L10n.settingsAboutHeader)
                } footer: {
                    Label(L10n.settingsAboutPromise, systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
            }
            .foregroundStyle(.primary)
            .navigationTitle(L10n.settingsTitle)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .alert(notice?.title ?? "", isPresented: isNoticePresented, presenting: notice) { _ in
                Button(L10n.commonClose, role: .cancel) {}
            } message: { notice in
                Text(notice.message)
            }
        }
    }

    /// Turning the lock on or off asks for Face ID / Touch ID / the passcode first, so someone else
    /// holding the phone cannot simply switch it off.
    private var historyLockBinding: Binding<Bool> {
        Binding(get: { settings.isHistoryLockEnabled }, set: { newValue in
            guard let historyLock else { return }
            Task {
                switch await historyLock.unlock() {
                case .unlocked: settings.isHistoryLockEnabled = newValue
                case .cancelled: break
                case .unavailable: isLockUnavailable = true
                }
            }
        })
    }

    private var proStatus: String {
        if store.isPro { return L10n.settingsProStatusPurchased }
        if let price = store.displayPrice { return L10n.settingsProStatusFreeWithPrice(price) }
        return L10n.settingsProStatusFree
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private var isNoticePresented: Binding<Bool> {
        Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })
    }
}

/// Chooses the site "ウェブで検索" opens (docs/design/19_product_search.svg F4).
struct SearchEnginePicker: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section {
                ForEach(SearchEngine.allCases) { engine in
                    Button {
                        settings.searchEngine = engine
                    } label: {
                        HStack {
                            Text(engine.title).foregroundStyle(.primary)
                            Spacer()
                            if settings.searchEngine == engine {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibilityAddTraits(settings.searchEngine == engine ? .isSelected : [])
                }
            } header: {
                Text(L10n.settingsSearchEngineHeader)
            } footer: {
                Text(L10n.settingsSearchEngineFooter)
            }
        }
        .navigationTitle(L10n.settingsScanSearchEngine)
        .navigationBarTitleDisplayMode(.inline)
    }
}
