import SwiftData
import SwiftUI
import UIKit

/// History of scanned and created codes. Compact width: list then detail; regular width: list | detail.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.isProUnlocked) private var isPro
    @Environment(\.selectTab) private var selectTab
    @Environment(\.requestPro) private var requestPro
    @Environment(\.isHistorySearchPresented) private var isSearchPresented
    /// Optional so screens built without RootView (tests) work; nil means no lock.
    @Environment(HistoryLock.self) private var lock: HistoryLock?

    @Query(sort: \ScanRecord.createdAt, order: .reverse) private var records: [ScanRecord]

    @State private var query = HistoryQuery()
    @State private var selection: PersistentIdentifier?
    @State private var isConfirmingDeleteAll = false

    /// `initialSelection` opens a record's detail right away (used by the App Store screenshot test).
    init(initialSelection: PersistentIdentifier? = nil) {
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        if settings.isHistoryLockEnabled, let lock, !lock.isUnlocked {
            HistoryLockedView(lock: lock)
        } else {
            unlockedBody
        }
    }

    private var unlockedBody: some View {
        NavigationSplitView {
            list
                .navigationTitle(L10n.historyTitle)
                .toolbar { toolbarContent }
        } detail: {
            if let selection, let record = records.first(where: { $0.persistentModelID == selection }) {
                HistoryDetailView(record: record) {
                    delete(record)
                }
            } else {
                ContentUnavailableView(
                    L10n.historyDetailEmptyTitle,
                    systemImage: "clock",
                    description: Text(L10n.historyDetailEmptyMessage)
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: isSearchPresented.wrappedValue) { _, presented in
            // ⌘F with no history: there is no search field to activate.
            if presented, records.isEmpty { isSearchPresented.wrappedValue = false }
        }
        .confirmationDialog(L10n.historyDeleteAllTitle, isPresented: $isConfirmingDeleteAll, titleVisibility: .visible) {
            Button(L10n.historyDeleteAll, role: .destructive, action: deleteAll)
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.historyDeleteAllMessage(records.count))
        }
    }

    // MARK: List

    private var filtered: [ScanRecord] {
        guard query.isFiltering else { return records }
        return records.filter { record in
            query.matches(record.entry, kindTitle: record.kind.title, dateTexts: HistoryDateText.searchable(record.createdAt))
        }
    }

    @ViewBuilder
    private var list: some View {
        if records.isEmpty {
            emptyState
        } else {
            let sections = HistorySection.group(filtered)
            List(selection: $selection) {
                Section {
                    HistoryFilterBar(query: $query)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                    if !isPro {
                        Button { requestPro(.unlimitedHistory) } label: {
                            FreePlanBanner(count: records.count)
                        }
                        .buttonStyle(.plain)
                        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .hoverEffect(.highlight)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(section.records) { record in
                            NavigationLink(value: record.persistentModelID) {
                                HistoryRow(record: record)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label(L10n.historyDelete, systemImage: "trash")
                                }
                                Button {
                                    toggleFavorite(record)
                                } label: {
                                    Label(record.isFavorite ? L10n.resultFavoriteRemove : L10n.resultFavoriteAdd, systemImage: record.isFavorite ? "star.slash" : "star")
                                }
                                .tint(AppColor.favoriteFill)
                            }
                            // Secondary click on iPad (right click / two-finger tap); long press on iPhone.
                            .contextMenu {
                                Button {
                                    toggleFavorite(record)
                                } label: {
                                    Label(record.isFavorite ? L10n.resultFavoriteRemove : L10n.resultFavoriteAdd, systemImage: record.isFavorite ? "star.slash" : "star")
                                }
                                Button {
                                    UIPasteboard.general.string = record.content
                                } label: {
                                    Label(L10n.commonCopy, systemImage: "doc.on.doc")
                                }
                                ShareLink(item: record.content) {
                                    Label(L10n.commonShare, systemImage: "square.and.arrow.up")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label(L10n.historyDelete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query.text, isPresented: isSearchPresented, prompt: Text(L10n.historySearchPrompt))
            .overlay {
                if filtered.isEmpty {
                    noResults
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if settings.isAutosaveEnabled {
            ContentUnavailableView {
                Label(L10n.historyEmptyTitle, systemImage: "clock")
            } description: {
                Text(L10n.historyEmptyMessage)
            } actions: {
                Button(L10n.historyEmptyAction) { selectTab(.scan) }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.accentFill)
            }
        } else {
            ContentUnavailableView {
                Label(L10n.historyAutosaveOffTitle, systemImage: "clock.badge.xmark")
            } description: {
                Text(L10n.historyAutosaveOffMessage)
            } actions: {
                Button(L10n.historyAutosaveOffAction) { selectTab(.settings) }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.accentFill)
            }
        }
    }

    private var noResults: some View {
        ContentUnavailableView {
            Label(
                query.normalizedText.isEmpty ? L10n.historyNoResultsFilterTitle : L10n.historyNoResultsTitle(query.normalizedText),
                systemImage: "magnifyingglass"
            )
        } description: {
            Text(L10n.historyNoResultsMessage)
        } actions: {
            Button(L10n.historyNoResultsAction) { query = HistoryQuery() }
                .buttonStyle(.bordered)
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !records.isEmpty {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isPro {
                    ShareLink(
                        item: HistoryCSVFile(entries: records.map(\.entry)),
                        preview: SharePreview(L10n.historyExportCsv)
                    ) {
                        Label(L10n.historyExportCsv, systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button { requestPro(.csvExport) } label: {
                        Label(L10n.historyExportCsv, systemImage: "square.and.arrow.up")
                    }
                }
                Button(role: .destructive) {
                    isConfirmingDeleteAll = true
                } label: {
                    Label(L10n.historyDeleteAll, systemImage: "trash")
                }
            }
        }
    }

    // MARK: Actions

    private func delete(_ record: ScanRecord) {
        if selection == record.persistentModelID { selection = nil }
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func deleteAll() {
        selection = nil
        try? modelContext.delete(model: ScanRecord.self)
        try? modelContext.save()
    }

    private func toggleFavorite(_ record: ScanRecord) {
        record.isFavorite.toggle()
        try? modelContext.save()
    }
}

extension ScanRecord {
    var entry: HistoryEntry {
        HistoryEntry(content: content, kind: kind, symbology: symbology, source: source, createdAt: createdAt, isFavorite: isFavorite)
    }
}

/// Records grouped by calendar day, newest first.
struct HistorySection: Identifiable {
    let id: Date
    let title: String
    let records: [ScanRecord]

    @MainActor
    static func group(_ records: [ScanRecord], calendar: Calendar = .current) -> [HistorySection] {
        var order: [Date] = []
        var buckets: [Date: [ScanRecord]] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.createdAt)
            if buckets[day] == nil { order.append(day) }
            buckets[day, default: []].append(record)
        }
        return order.map { day in
            let title: String
            if calendar.isDateInToday(day) {
                title = L10n.historySectionToday
            } else if calendar.isDateInYesterday(day) {
                title = L10n.historySectionYesterday
            } else {
                title = day.formatted(date: .long, time: .omitted)
            }
            return HistorySection(id: day, title: title, records: buckets[day] ?? [])
        }
    }
}

/// Shown instead of the history while it is locked (docs/design/20_history_lock.svg G2).
struct HistoryLockedView: View {
    let lock: HistoryLock
    @State private var isUnlocking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 112, height: 112)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                Text(L10n.historyLockedTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(L10n.historyLockedMessage(HistoryLock.methodName))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await unlock() }
                } label: {
                    Label(L10n.historyLockedUnlock(HistoryLock.methodName), systemImage: "lock.open")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isUnlocking)
                .frame(maxWidth: 420)
                Text(L10n.historyLockedNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.historyTitle)
        }
        // Ask right away when the tab opens; the button is there if the person cancels.
        .task { await unlock() }
    }

    private func unlock() async {
        guard !isUnlocking, !lock.isUnlocked else { return }
        isUnlocking = true
        await lock.unlock()
        isUnlocking = false
    }
}
