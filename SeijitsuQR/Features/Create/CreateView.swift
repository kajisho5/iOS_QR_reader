import SwiftUI

extension CreateKind {
    var title: String {
        switch self {
        case .text: L10n.createKindText
        case .url: L10n.createKindUrl
        case .wifi: L10n.createKindWifi
        case .contact: L10n.createKindContact
        case .event: L10n.createKindEvent
        }
    }

    var detail: String {
        switch self {
        case .text: L10n.createKindTextDetail
        case .url: L10n.createKindUrlDetail
        case .wifi: L10n.createKindWifiDetail
        case .contact: L10n.createKindContactDetail
        case .event: L10n.createKindEventDetail
        }
    }
}

/// QR creation. Compact width: a grid of kinds, then a form; regular width: kinds | form + preview.
/// Locked kinds open the purchase screen only when tapped.
struct CreateView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isProUnlocked) private var isPro
    @Environment(\.requestPro) private var requestPro

    @State private var path: [CreateKind] = []
    @State private var selection: CreateKind? = .text

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(selection: $selection) {
                    Section {
                        ForEach(CreateKind.allCases) { kind in
                            CreateKindRow(kind: kind, isLocked: isLocked(kind))
                                .tag(kind)
                        }
                    } footer: {
                        if !isPro { LockedNotice().padding(.top, 8) }
                    }
                }
                .navigationTitle(L10n.createTitle)
                .onChange(of: selection) { old, new in
                    if let new, isLocked(new) {
                        selection = old
                        requestPro(.allCodeTypes)
                    }
                }
            } detail: {
                if let selection, !isLocked(selection) {
                    CreateFormView(kind: selection)
                        .id(selection)
                }
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            NavigationStack(path: $path) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.createSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                            ForEach(CreateKind.allCases) { kind in
                                Button { open(kind) } label: {
                                    CreateKindCard(kind: kind, isLocked: isLocked(kind))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !isPro { LockedNotice() }
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(L10n.createTitle)
                .navigationDestination(for: CreateKind.self) { kind in
                    CreateFormView(kind: kind)
                }
            }
        }
    }

    private func isLocked(_ kind: CreateKind) -> Bool { kind.requiresPro && !isPro }

    private func open(_ kind: CreateKind) {
        if isLocked(kind) {
            requestPro(.allCodeTypes)
        } else {
            path.append(kind)
        }
    }
}

private struct CreateKindCard: View {
    let kind: CreateKind
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                KindTile(kind: kind.payloadKind, size: 44)
                    .saturation(isLocked ? 0 : 1)
                Spacer()
                CreateBadge(isLocked: isLocked)
            }
            Text(kind.title)
                .font(.headline)
                .foregroundStyle(isLocked ? .secondary : .primary)
            Text(kind.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? L10n.createLockedA11y(kind.title) : kind.title)
        .accessibilityHint(kind.detail)
        .accessibilityAddTraits(.isButton)
    }
}

private struct CreateKindRow: View {
    let kind: CreateKind
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            KindTile(kind: kind.payloadKind, size: 32)
                .saturation(isLocked ? 0 : 1)
            Text(kind.title)
                .foregroundStyle(isLocked ? .secondary : .primary)
            Spacer()
            CreateBadge(isLocked: isLocked)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? L10n.createLockedA11y(kind.title) : kind.title)
    }
}

private struct CreateBadge: View {
    let isLocked: Bool

    var body: some View {
        Group {
            if isLocked {
                Label(L10n.createBadgePro, systemImage: "lock.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(AppColor.accentOnSoft)
            } else {
                Text(L10n.createBadgeFree)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(isLocked ? AnyShapeStyle(AppColor.accentSoft) : AnyShapeStyle(Color(.tertiarySystemFill))))
        .accessibilityHidden(true)
    }
}

private struct LockedNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.open")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.createLockedTitle)
                    .font(.footnote.weight(.bold))
                Text(L10n.createLockedMessage)
                    .font(.caption)
            }
            .foregroundStyle(AppColor.accentOnSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
