import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct HistoryRow: View {
    let record: ScanRecord

    var body: some View {
        HStack(spacing: 12) {
            KindTile(kind: record.kind, symbology: record.symbology, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                    .truncationMode(.middle)
                Text(meta)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if record.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColor.favoriteTint)
                    .accessibilityLabel(L10n.resultFavorite)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var meta: String {
        let origin = record.source == .created ? L10n.sourceCreated : (record.symbology?.title ?? "")
        return [record.kind.title, origin, record.createdAt.formatted(date: .omitted, time: .shortened)]
            .filter { !$0.isEmpty }
            .joined(separator: L10n.metaSeparator)
    }
}

/// Kind and favorite filters as a horizontally scrolling row of chips.
struct HistoryFilterBar: View {
    @Binding var query: HistoryQuery

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(L10n.historyFilterAll, isOn: query.kind == nil && !query.favoritesOnly) {
                    query.kind = nil
                    query.favoritesOnly = false
                }
                chip(L10n.historyFilterFavorites, systemImage: "star.fill", isOn: query.favoritesOnly) {
                    query.favoritesOnly.toggle()
                }
                ForEach(PayloadKind.allCases, id: \.self) { kind in
                    chip(kind.title, isOn: query.kind == kind) {
                        query.kind = query.kind == kind ? nil : kind
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityLabel(L10n.historyFilterLabel)
    }

    private func chip(_ title: String, systemImage: String? = nil, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(isOn ? Color.white : AppColor.favoriteTint)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background {
                Capsule().fill(isOn ? AnyShapeStyle(AppColor.accentFill) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
            }
            .overlay {
                if !isOn { Capsule().strokeBorder(Color(.separator)) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Free plan notice. Tapping it opens the purchase screen (never shown automatically).
struct FreePlanBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "infinity")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.historyFreeTitle)
                    .font(.subheadline.weight(.bold))
                Text(L10n.historyFreeCount(min(count, HistoryRecorder.freeLimit), HistoryRecorder.freeLimit))
                    .font(.caption)
            }
            .foregroundStyle(AppColor.accentOnSoft)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(AppColor.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Detail screen for one history record; reuses the scan result view.
struct HistoryDetailView: View {
    let record: ScanRecord
    let onDelete: () -> Void

    var body: some View {
        ResultView(result: ScanResult(record: record), style: .pane)
            .id(record.persistentModelID)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive, action: onDelete) {
                        Label(L10n.historyDelete, systemImage: "trash")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension ScanResult {
    init(record: ScanRecord) {
        self.init(
            code: DetectedCode(content: record.content, symbology: record.symbology ?? .qr),
            source: record.source,
            payload: PayloadParser.parse(record.content),
            date: record.createdAt,
            recordID: record.persistentModelID
        )
    }
}

/// The history as a CSV file, written only when the user shares it (Pro).
struct HistoryCSVFile: Transferable {
    let entries: [HistoryEntry]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let csv = Self.exporter.makeCSV(file.entries)
            let url = FileManager.default.temporaryDirectory.appending(path: Self.fileName())
            try Data(csv.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    private static var exporter: CSVExporter {
        CSVExporter(labels: .init(
            headers: [L10n.csvHeaderDate, L10n.csvHeaderKind, L10n.csvHeaderContent, L10n.csvHeaderSymbology, L10n.csvHeaderSource, L10n.csvHeaderFavorite],
            kindTitle: { $0.title },
            symbologyTitle: { $0.title },
            sourceTitle: { source in
                switch source {
                case .camera: L10n.sourceCamera
                case .photo: L10n.sourcePhoto
                case .created: L10n.sourceCreated
                }
            },
            favoriteYes: L10n.commonYes,
            favoriteNo: L10n.commonNo
        ))
    }

    private static func fileName() -> String {
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        return "SeijitsuQR-History-\(stamp).csv"
    }
}
