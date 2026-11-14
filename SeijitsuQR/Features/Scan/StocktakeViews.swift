import CoreTransferable
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// The counts while counting (docs/design/26_stocktake.svg I2), over the camera.
struct CountingTray: View {
    @Binding var session: StocktakeSession
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(L10n.scanCountTitle, systemImage: "list.number")
                        .font(.headline)
                    Text(L10n.scanCountSummary(session.items.count, session.total))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button(L10n.scanTrayEnd, action: onEnd)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.accentOnCamera)
                    .frame(minHeight: 44)
            }
            if session.isEmpty {
                Text(L10n.scanCountEmpty)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(session.items) { item in
                            CountRow(item: item,
                                     onMinus: { session.decrement(item.id) },
                                     onPlus: { session.increment(item.id) })
                        }
                    }
                }
                .frame(maxHeight: 156)
            }
            Text(L10n.scanCountHint)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black.opacity(0.78)))
    }
}

private struct CountRow: View {
    let item: StocktakeSession.Item
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.code.content)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(item.code.symbology.title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 8)
            Button(action: onMinus) { Image(systemName: "minus") }
                .buttonStyle(CountButtonStyle())
                .disabled(item.count <= 1)
                .accessibilityLabel(L10n.scanCountMinus(item.code.content))
            Text(item.count, format: .number)
                .font(.title3.weight(.heavy).monospacedDigit())
                .frame(minWidth: 32)
            Button(action: onPlus) { Image(systemName: "plus") }
                .buttonStyle(CountButtonStyle())
                .accessibilityLabel(L10n.scanCountPlus(item.code.content))
        }
        .padding(.vertical, 6)
    }
}

private struct CountButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.bold))
            .frame(width: 36, height: 36)
            .background(Circle().fill(.white.opacity(configuration.isPressed ? 0.28 : 0.14)))
    }
}

/// What was counted, and how to finish (docs/design/26_stocktake.svg I3).
struct StocktakeSummaryView: View {
    let session: StocktakeSession
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var saved = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.scanCountSummary(session.items.count, session.total))
                            .font(.title2.bold())
                        if let start = session.startedAt {
                            Text(start.formatted(date: .numeric, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    ForEach(session.items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.code.content).font(.body.monospaced().weight(.semibold)).lineLimit(2)
                                Text(item.code.symbology.title).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(L10n.scanCountPieces(item.count)).font(.headline.monospacedDigit())
                        }
                    }
                }
                Section {
                    ShareLink(item: StocktakeCSVFile(session: session), preview: SharePreview(L10n.scanCountCsvTitle)) {
                        Label(L10n.scanCountCsv, systemImage: "tablecells")
                    }
                    Button {
                        saveToHistory()
                    } label: {
                        Label(saved ? L10n.scanCountSaved : L10n.scanCountSave, systemImage: saved ? "checkmark" : "clock")
                    }
                    .disabled(saved || session.isEmpty)
                } footer: {
                    Text(L10n.scanCountFooter)
                }
            }
            .navigationTitle(L10n.scanCountResultTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.scanCountDone, action: onFinish)
                }
            }
        }
    }

    /// One history record per code (not per count). Counting is a Pro feature, so no free-plan trimming applies.
    private func saveToHistory() {
        let recorder = HistoryRecorder(context: modelContext)
        for item in session.items.reversed() {
            let draft = RecordDraft(content: item.code.content, kind: PayloadParser.parse(item.code.content).kind,
                                    symbology: item.code.symbology, source: .camera, createdAt: item.lastCounted)
            _ = try? recorder.record(draft, isPro: true)
        }
        saved = true
    }
}

/// The counts as a CSV file, written only when the user shares it.
struct StocktakeCSVFile: Transferable, Sendable {
    let session: StocktakeSession

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let csv = file.session.csv(
                headers: [L10n.scanCountCsvCode, L10n.csvHeaderKind, L10n.csvHeaderSymbology, L10n.scanCountCsvCount, L10n.scanCountCsvLast],
                kindTitle: { PayloadParser.parse($0.content).kind.title },
                symbologyTitle: { $0.title }
            )
            let stamp = Date.now.formatted(.iso8601.year().month().day())
            let url = FileManager.default.temporaryDirectory.appending(path: "seijitsu-count-\(stamp).csv")
            try Data(csv.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
