import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// The home screen widget (docs/DESIGN_1.1.md §4, B; docs/design/17_widget.svg): one favorite code, drawn again
// from its content. Pro only; without Pro it explains itself and opens the purchase screen.

/// A favorite the widget can show, as listed in the widget's edit screen.
struct FavoriteEntity: AppEntity {
    let id: UUID
    let title: String
    let kindTitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "お気に入り"
    static let defaultQuery = FavoriteQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(kindTitle)")
    }

    init(_ favorite: WidgetSnapshot.Favorite) {
        id = favorite.id
        title = favorite.title
        kindTitle = favorite.kindTitle
    }
}

struct FavoriteQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [FavoriteEntity] {
        favorites().filter { identifiers.contains($0.id) }.map(FavoriteEntity.init)
    }

    func suggestedEntities() async throws -> [FavoriteEntity] {
        favorites().map(FavoriteEntity.init)
    }

    private func favorites() -> [WidgetSnapshot.Favorite] {
        WidgetSnapshot.load()?.favorites ?? []
    }
}

struct SelectFavoriteIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "ウィジェットに表示するQR"
    static let description = IntentDescription("お気に入りから選びます。選んだコードはホーム画面に表示されます（Wi-Fi のパスワード入りの QR も、そのまま表示されます）。")

    @Parameter(title: "表示するQR")
    var favorite: FavoriteEntity?

    init() {}
}

struct FavoriteCodeEntry: TimelineEntry {
    let date: Date
    let isPro: Bool
    let favorite: WidgetSnapshot.Favorite?
    /// No favorite exists yet (as opposed to none chosen).
    let hasFavorites: Bool
}

struct FavoriteCodeProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FavoriteCodeEntry {
        FavoriteCodeEntry(date: .now, isPro: true, favorite: Self.sample, hasFavorites: true)
    }

    func snapshot(for configuration: SelectFavoriteIntent, in context: Context) async -> FavoriteCodeEntry {
        context.isPreview ? placeholder(in: context) : entry(for: configuration)
    }

    func timeline(for configuration: SelectFavoriteIntent, in context: Context) async -> Timeline<FavoriteCodeEntry> {
        // Nothing changes with time; the app reloads the widget when the favorites or Pro change.
        Timeline(entries: [entry(for: configuration)], policy: .never)
    }

    private func entry(for configuration: SelectFavoriteIntent) -> FavoriteCodeEntry {
        let snapshot = WidgetSnapshot.load()
        let favorites = snapshot?.favorites ?? []
        let chosen = configuration.favorite.flatMap { entity in favorites.first { $0.id == entity.id } }
        return FavoriteCodeEntry(date: .now, isPro: snapshot?.isPro ?? false, favorite: chosen ?? favorites.first, hasFavorites: !favorites.isEmpty)
    }

    static let sample = WidgetSnapshot.Favorite(id: UUID(), title: "お店のWi-Fi", kindTitle: "Wi-Fi", symbologyRaw: "qr", content: "WIFI:T:WPA;S:Sample;P:sample;;")
}

struct FavoriteCodeWidget: Widget {
    static let kind = "com.seventhwell.seijitsuqr.widget.favorite"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectFavoriteIntent.self, provider: FavoriteCodeProvider()) { entry in
            FavoriteCodeView(entry: entry)
                .containerBackground(Color.white, for: .widget)
        }
        .configurationDisplayName("お気に入りのQR")
        .description("お気に入りの QR コードやバーコードを、ホーム画面にそのまま表示します（Pro）。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FavoriteCodeView: View {
    let entry: FavoriteCodeEntry
    @Environment(\.widgetFamily) private var family

    private static let ink = Color(red: 0.11, green: 0.11, blue: 0.12)
    private static let secondary = Color(red: 0.42, green: 0.42, blue: 0.44)
    private static let accent = Color(red: 0.055, green: 0.486, blue: 0.4)

    var body: some View {
        Group {
            if !entry.isPro {
                message(title: "Pro で使えます", detail: "タップして詳細")
                    .widgetURL(URL(string: "seijitsuqr://pro"))
            } else if let favorite = entry.favorite {
                code(favorite)
                    .widgetURL(URL(string: "seijitsuqr://open"))
            } else {
                message(title: entry.hasFavorites ? "QR を選んでください" : "お気に入りがありません",
                        detail: entry.hasFavorites ? "長押しして「ウィジェットを編集」" : "アプリの履歴で ☆ を付けてください")
                    .widgetURL(URL(string: "seijitsuqr://open"))
            }
        }
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private func code(_ favorite: WidgetSnapshot.Favorite) -> some View {
        let symbology = favorite.symbologyRaw.flatMap(CodeSymbology.init(rawValue:)) ?? .qr
        let image = CodeImageRenderer.image(for: favorite.content, symbology: symbology, targetWidth: 400)
        if family == .systemMedium {
            HStack(spacing: 14) {
                codeImage(image)
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.kindTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Self.secondary)
                    Text(favorite.title)
                        .font(.headline)
                        .foregroundStyle(Self.ink)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Text("誠実QRリーダー")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Self.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 6) {
                codeImage(image)
                Text(favorite.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Self.ink)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func codeImage(_ image: UIImage?) -> some View {
        if let image {
            if #available(iOS 18.0, *) {
                // On a tinted home screen, keep the code black on white so scanners can still read it.
                Image(uiImage: image).interpolation(.none).resizable().widgetAccentedRenderingMode(.fullColor)
                    .scaledToFit()
                    .accessibilityLabel("QRコード")
            } else {
                Image(uiImage: image).interpolation(.none).resizable()
                    .scaledToFit()
                    .accessibilityLabel("QRコード")
            }
        } else {
            Image(systemName: "qrcode")
                .font(.largeTitle)
                .foregroundStyle(Self.secondary)
        }
    }

    private func message(title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Self.accent, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(Self.accent)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(Self.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
