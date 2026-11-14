import SwiftData
import SwiftUI

/// "Apple Watch" in Settings (docs/design/28_apple_watch.svg K1). Shown only when a watch with the app is paired.
struct WatchSettingsSection: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isProUnlocked) private var isPro
    @Environment(\.requestPro) private var requestPro

    var body: some View {
        Section {
            Toggle(L10n.settingsWatchShow, isOn: enabled)
                .tint(AppColor.accentFill)
            if settings.isWatchEnabled && isPro {
                NavigationLink {
                    WatchFavoritesPicker()
                } label: {
                    LabeledContent(L10n.settingsWatchCodes, value: L10n.settingsWatchCount(settings.watchCodeIDs.count))
                }
            }
        } header: {
            Text(L10n.settingsWatchHeader)
        } footer: {
            Text(L10n.settingsWatchFooter)
        }
    }

    private var enabled: Binding<Bool> {
        Binding {
            settings.isWatchEnabled && isPro
        } set: { on in
            guard isPro else {
                requestPro(.allCodeTypes)
                return
            }
            settings.isWatchEnabled = on
            WatchLink.shared.update(context: modelContext, settings: settings, isPro: isPro)
        }
    }
}

/// Choose which favorites appear on the watch (up to WatchCodes.limit).
private struct WatchFavoritesPicker: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isProUnlocked) private var isPro
    @Query(filter: #Predicate<ScanRecord> { $0.isFavorite }, sort: \ScanRecord.createdAt, order: .reverse)
    private var favorites: [ScanRecord]

    var body: some View {
        List {
            if favorites.isEmpty {
                Text(L10n.settingsWatchNoFavorites)
                    .foregroundStyle(.secondary)
            }
            Section {
                ForEach(favorites) { record in
                    let id = record.id.uuidString
                    let isOn = settings.watchCodeIDs.contains(id)
                    Button {
                        toggle(id, isOn: isOn)
                    } label: {
                        HStack {
                            KindTile(kind: record.kind, symbology: record.symbology, size: 30)
                            Text(WidgetSnapshotWriter.title(for: record))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isOn ? Color.accentColor : Color(.tertiaryLabel))
                        }
                    }
                    .disabled(!isOn && settings.watchCodeIDs.count >= WatchCodes.limit)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            } footer: {
                Text(L10n.settingsWatchPickerFooter(WatchCodes.limit))
            }
        }
        .navigationTitle(L10n.settingsWatchCodes)
    }

    private func toggle(_ id: String, isOn: Bool) {
        if isOn { settings.watchCodeIDs.remove(id) } else { settings.watchCodeIDs.insert(id) }
        WatchLink.shared.update(context: modelContext, settings: settings, isPro: isPro)
    }
}
