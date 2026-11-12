import SwiftData
import SwiftUI
import UIKit

/// Details and actions for one code. Shown in a sheet (compact width) or a side pane (regular width).
/// On compact width the actions are pinned to the bottom, within thumb reach.
struct ResultView: View {
    enum Style {
        case sheet
        case pane
    }

    let result: ScanResult
    var style: Style = .sheet
    /// Set when this view is itself in a sheet: the caller closes it before showing the contact
    /// form, so sheets are never stacked. When nil the contact form opens from here.
    var addContact: ((ContactCard) -> Void)?
    /// Shows the note field (history detail only; docs/DESIGN_1.2.md §3, H).
    var showsNote = false

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isFavorite = false
    @State private var isPasswordVisible = false
    @State private var copiedMessageVisible = false
    @State private var isAddingContact = false
    @State private var isConnecting = false
    @State private var alert: ResultAlert?
    @State private var displayedCode: DisplayedCode?
    @State private var riskyURL: URL?
    @State private var memoText = ""
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if style == .pane, canShowCode {
                    codePreview
                }
                header
                details
                if showsNote, result.recordID != nil {
                    noteEditor
                }
                if !canShowCode {
                    Label(L10n.resultShowCodeUnavailableNote, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let note = noteText {
                    Label(note, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !pinsActions {
                    actions
                }
                footer
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            if pinsActions {
                VStack(spacing: 8) {
                    actions
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                }
                .overlay(alignment: .top) { Divider() }
            }
        }
        .onAppear(perform: loadFavorite)
        .onChange(of: result.id) { loadFavorite() }
        .onDisappear { if showsNote { saveNote() } }
        .sheet(isPresented: $isAddingContact) {
            if case .contact(let card) = result.payload {
                ContactAddView(card: card) { isAddingContact = false }
                    .ignoresSafeArea()
            }
        }
        .alert(alert?.title ?? "", isPresented: isAlertPresented, presenting: alert) { _ in
            Button(L10n.commonClose, role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
        .fullScreenCover(item: $displayedCode) { code in
            CodeDisplayView(image: code.image, title: code.title, subtitle: code.subtitle)
        }
        .confirmationDialog(L10n.urlRiskConfirmTitle, isPresented: isConfirmingRiskyURL, titleVisibility: .visible, presenting: riskyURL) { url in
            Button(L10n.urlRiskConfirmOpen, role: .destructive) { open(url) }
            Button(L10n.urlRiskConfirmCancel, role: .cancel) {}
        } message: { _ in
            Text(urlRisks.map { riskTitle($0.kind) }.joined(separator: L10n.metaSeparator))
        }
    }

    /// Pinned on compact width. At accessibility text sizes the actions follow the content instead,
    /// because a pinned bar would cover most of the screen.
    private var pinsActions: Bool {
        horizontalSizeClass == .compact && !dynamicTypeSize.isAccessibilitySize
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })
    }

    // MARK: Header

    private var header: some View {
        AdaptiveStack(spacing: 12) {
            KindTile(kind: result.payload.kind, symbology: result.code.symbology, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.title2.bold())
                Text(metaText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var headerTitle: String {
        if isBook { return L10n.resultBookTitle }
        if isProductCode { return L10n.resultProductTitle }
        return result.payload.kind.title
    }

    private var isProductCode: Bool { ProductCode.isProductCode(result.code.symbology) }
    private var isBook: Bool { ProductCode.isISBN(result.code.content, symbology: result.code.symbology) }

    private func webSearch(_ query: String) {
        guard let url = settings.searchEngine.url(searching: query) else { return }
        open(url)
    }

    private var metaText: String {
        // Pasted text has no symbology of its own: say where it came from instead.
        let origin = result.source == .paste ? L10n.sourcePaste : result.code.symbology.title
        return [origin, result.date.formatted(date: .numeric, time: .shortened)].joined(separator: L10n.metaSeparator)
    }

    // MARK: Details

    @ViewBuilder
    private var details: some View {
        switch result.payload {
        case .url(let url):
            ForEach(urlRisks, id: \.self) { risk in
                URLRiskCard(risk: risk, title: riskTitle(risk.kind), message: riskMessage(risk.kind))
            }
            ResultCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.resultLinkFull)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(highlightedURL(url))
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ResultRow(title: L10n.resultDomain, value: url.host ?? "")
                ResultRow(
                    title: L10n.resultScheme,
                    value: url.scheme?.lowercased() == "https" ? L10n.resultSchemeHttps : L10n.resultSchemeHttp,
                    systemImage: url.scheme?.lowercased() == "https" ? "lock.fill" : "lock.open"
                )
            }
        case .wifi(let network):
            ResultCard {
                ResultRow(title: L10n.resultWifiSsid, value: network.ssid)
                ResultRow(title: L10n.resultWifiSecurity, value: securityTitle(network.security))
                if network.security != .open {
                    passwordRow(network.password)
                }
                ResultRow(title: L10n.resultWifiHidden, value: network.isHidden ? L10n.commonYes : L10n.commonNo)
            }
        case .contact(let card):
            ResultCard {
                if let name = card.displayName { ResultRow(title: L10n.resultContactName, value: name) }
                ForEach(card.phoneNumbers, id: \.self) { ResultRow(title: L10n.resultContactPhone, value: $0) }
                ForEach(card.emails, id: \.self) { ResultRow(title: L10n.resultContactEmail, value: $0) }
                if let org = card.organization { ResultRow(title: L10n.resultContactOrganization, value: org) }
                if let title = card.jobTitle { ResultRow(title: L10n.resultContactTitle, value: title) }
                ForEach(card.addresses, id: \.self) { ResultRow(title: L10n.resultContactAddress, value: $0) }
                ForEach(card.urls, id: \.self) { ResultRow(title: L10n.resultContactUrl, value: $0) }
            }
        case .email(let message):
            ResultCard {
                ResultRow(title: L10n.resultEmailTo, value: message.address)
                if let subject = message.subject { ResultRow(title: L10n.resultEmailSubject, value: subject) }
                if let body = message.body { ResultRow(title: L10n.resultEmailBody, value: body) }
            }
        case .phone(let number):
            ResultCard { ResultRow(title: L10n.resultPhoneNumber, value: number) }
        case .sms(let message):
            ResultCard {
                ResultRow(title: L10n.resultSmsNumber, value: message.number)
                if let body = message.body { ResultRow(title: L10n.resultSmsBody, value: body) }
            }
        case .geo(let point):
            ResultCard {
                ResultRow(title: L10n.resultGeoLatitude, value: String(point.latitude))
                ResultRow(title: L10n.resultGeoLongitude, value: String(point.longitude))
                if let query = point.query { ResultRow(title: L10n.resultGeoLabel, value: query) }
            }
        case .event(let text), .text(let text):
            ResultCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.resultContent)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(text)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func passwordRow(_ password: String?) -> some View {
        HStack {
            Text(L10n.resultWifiPassword)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            if let password, !password.isEmpty {
                Text(isPasswordVisible ? password : String(repeating: "•", count: min(password.count, 12)))
                    .font(.body.monospaced().weight(.semibold))
                    .textSelection(.enabled)
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(isPasswordVisible ? L10n.resultWifiPasswordHide : L10n.resultWifiPasswordShow)
            } else {
                Text(L10n.resultWifiPasswordNone)
                    .fontWeight(.semibold)
            }
        }
    }

    private func highlightedURL(_ url: URL) -> AttributedString {
        let raw = result.code.content.trimmingCharacters(in: .whitespacesAndNewlines)
        var text = AttributedString(raw)
        if let host = url.host, let range = text.range(of: host) {
            text[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return text
    }

    private func securityTitle(_ security: WiFiNetwork.Security) -> String {
        switch security {
        case .wpa: L10n.resultWifiSecurityWpa
        case .wep: L10n.resultWifiSecurityWep
        case .open: L10n.resultWifiSecurityOpen
        }
    }

    private var noteText: String? {
        if isProductCode { return L10n.resultWebSearchNote(settings.searchEngine.title) }
        return switch result.payload {
        case .url: L10n.resultOpenNote
        case .wifi: L10n.resultWifiConnectNote
        default: nil
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        if let primary = primaryAction {
            Button(action: primary.perform) {
                Label(primary.title, systemImage: primary.systemImage)
            }
            .buttonStyle(PrimaryButtonStyle())
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(isConnecting)
        }
        AdaptiveStack(spacing: 8, alignment: .center) {
            if isBook {
                Button {
                    webSearch("ISBN " + result.code.content)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "book").font(.title3)
                        Text(L10n.resultBookSearch).multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(ActionTileStyle())
                .foregroundStyle(Color.accentColor)
            }
            Button(action: showCode) {
                VStack(spacing: 6) {
                    Image(systemName: result.code.symbology == .qr ? "qrcode" : "barcode").font(.title3)
                    Text(canShowCode ? showCodeTitle : L10n.resultShowCodeUnavailable).multilineTextAlignment(.center)
                }
            }
            .buttonStyle(ActionTileStyle())
            .foregroundStyle(canShowCode ? Color.accentColor : Color.secondary)
            .disabled(!canShowCode)
            .keyboardShortcut("e", modifiers: .command)

            Button(action: copy) {
                VStack(spacing: 6) {
                    Image(systemName: "doc.on.doc").font(.title3)
                    Text(copyTitle).multilineTextAlignment(.center)
                }
            }
            .buttonStyle(ActionTileStyle())
            .foregroundStyle(Color.accentColor)
            .keyboardShortcut("c", modifiers: [.command, .shift])

            ShareLink(item: result.code.content) {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up").font(.title3)
                    Text(L10n.commonShare)
                }
            }
            .buttonStyle(ActionTileStyle())
            .foregroundStyle(Color.accentColor)

            if result.recordID != nil {
                Button(action: toggleFavorite) {
                    VStack(spacing: 6) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(AppColor.favoriteTint)
                        Text(L10n.resultFavorite)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(ActionTileStyle())
                .keyboardShortcut("d", modifiers: .command)
                .accessibilityLabel(isFavorite ? L10n.resultFavoriteRemove : L10n.resultFavoriteAdd)
            }
        }
    }

    // MARK: Showing the code again

    private struct DisplayedCode: Identifiable {
        let id = UUID()
        let image: UIImage
        let title: String
        let subtitle: String
    }

    private var canShowCode: Bool {
        CodeImageRenderer.canRender(result.code.symbology, content: result.code.content)
    }

    private var showCodeTitle: String {
        result.code.symbology == .qr ? L10n.resultShowCode : L10n.resultShowBarcode
    }

    private var codeTitle: String {
        switch result.payload {
        case .wifi(let network): network.ssid
        case .url(let url): url.host ?? result.payload.kind.title
        default: result.payload.kind.title
        }
    }

    private func showCode() {
        guard let image = CodeImageRenderer.image(for: result.code.content, symbology: result.code.symbology) else { return }
        displayedCode = DisplayedCode(image: image, title: codeTitle, subtitle: result.payload.kind.title)
    }

    /// History detail and the iPad pane show the code itself at the top; tap to enlarge.
    private var codePreview: some View {
        Button(action: showCode) {
            VStack(spacing: 10) {
                if let image = CodeImageRenderer.image(for: result.code.content, symbology: result.code.symbology, targetWidth: 400) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .padding(8)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                Label(L10n.resultCodePreviewHint, systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showCodeTitle)
    }

    // MARK: URL risks

    private var urlRisks: [URLRisk] {
        guard case .url(let url) = result.payload else { return [] }
        return URLRiskAnalyzer.risks(in: result.code.content, url: url)
    }

    private var isConfirmingRiskyURL: Binding<Bool> {
        Binding(get: { riskyURL != nil }, set: { if !$0 { riskyURL = nil } })
    }

    private func riskTitle(_ kind: URLRisk.Kind) -> String {
        switch kind {
        case .lookalikeCharacters: L10n.urlRiskLookalikeTitle
        case .disguisedHost: L10n.urlRiskDisguisedTitle
        case .shortener: L10n.urlRiskShortenerTitle
        case .insecure: L10n.urlRiskInsecureTitle
        case .ipAddress: L10n.urlRiskIpTitle
        case .unusualPort(let port): L10n.urlRiskPortTitle(String(port))
        }
    }

    private func riskMessage(_ kind: URLRisk.Kind) -> String {
        switch kind {
        case .lookalikeCharacters(let shown, let actual):
            shown == actual ? L10n.urlRiskLookalikeMessage : L10n.urlRiskLookalikeMessage + "\n" + L10n.urlRiskActualDomain(actual)
        case .disguisedHost(let shown, let actual):
            L10n.urlRiskDisguisedMessage(shown) + "\n" + L10n.urlRiskActualDomain(actual)
        case .shortener: L10n.urlRiskShortenerMessage
        case .insecure: L10n.urlRiskInsecureMessage
        case .ipAddress: L10n.urlRiskIpMessage
        case .unusualPort: L10n.urlRiskPortMessage
        }
    }

    private var footer: some View {
        Group {
            if copiedMessageVisible {
                Label(L10n.commonCopied, systemImage: "checkmark.circle.fill")
            } else if result.recordID != nil {
                Label(L10n.resultSaved, systemImage: "checkmark.circle.fill")
            } else {
                Label(L10n.resultNotSaved, systemImage: "info.circle")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    private struct PrimaryAction {
        let title: String
        let systemImage: String
        let perform: () -> Void
    }

    private var primaryAction: PrimaryAction? {
        if isProductCode {
            let code = result.code.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return PrimaryAction(title: L10n.resultWebSearch, systemImage: "magnifyingglass") { webSearch(code) }
        }
        return switch result.payload {
        case .url(let url):
            PrimaryAction(title: L10n.resultOpenInBrowser, systemImage: "arrow.up.right.square") {
                // A URL with something to note asks once more before leaving the app.
                if urlRisks.isEmpty { open(url) } else { riskyURL = url }
            }
        case .wifi(let network):
            PrimaryAction(title: L10n.resultWifiConnect, systemImage: "wifi") { connect(network) }
        case .contact(let card):
            PrimaryAction(title: L10n.resultContactAdd, systemImage: "person.crop.circle.badge.plus") {
                if let addContact {
                    addContact(card)
                } else {
                    isAddingContact = true
                }
            }
        case .email(let message):
            ActionURLs.mail(message).map { url in PrimaryAction(title: L10n.resultEmailCompose, systemImage: "envelope") { open(url) } }
        case .phone(let number):
            ActionURLs.phone(number).map { url in PrimaryAction(title: L10n.resultPhoneCall, systemImage: "phone") { open(url) } }
        case .sms(let message):
            ActionURLs.sms(message).map { url in PrimaryAction(title: L10n.resultSmsCompose, systemImage: "message") { open(url) } }
        case .geo(let point):
            ActionURLs.maps(point).map { url in PrimaryAction(title: L10n.resultGeoOpenMaps, systemImage: "map") { open(url) } }
        case .event, .text:
            nil
        }
    }

    private var copyTitle: String {
        if case .wifi(let network) = result.payload, network.password?.isEmpty == false {
            return L10n.resultWifiCopyPassword
        }
        return L10n.commonCopy
    }

    private func copy() {
        if case .wifi(let network) = result.payload, let password = network.password, !password.isEmpty {
            UIPasteboard.general.string = password
        } else {
            UIPasteboard.general.string = result.code.content
        }
        copiedMessageVisible = true
        AccessibilityNotification.Announcement(L10n.commonCopied).post()
        Task {
            try? await Task.sleep(for: .seconds(2))
            copiedMessageVisible = false
        }
    }

    private func open(_ url: URL) {
        openURL(url) { accepted in
            if !accepted {
                alert = ResultAlert(title: L10n.resultOpenFailedTitle, message: L10n.resultOpenFailedMessage)
            }
        }
    }

    private func connect(_ network: WiFiNetwork) {
        isConnecting = true
        Task {
            let outcome = await WiFiConnector.connect(network)
            isConnecting = false
            switch outcome {
            case .connected:
                AccessibilityNotification.Announcement(L10n.resultWifiConnected).post()
            case .cancelled:
                break
            case .failed:
                alert = ResultAlert(title: L10n.resultWifiFailedTitle, message: L10n.resultWifiFailedMessage)
            }
        }
    }

    private func loadFavorite() {
        guard let id = result.recordID, let record = modelContext.model(for: id) as? ScanRecord else {
            isFavorite = false
            memoText = ""
            return
        }
        isFavorite = record.isFavorite
        memoText = record.note ?? ""
    }

    // MARK: Note

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.resultNoteTitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(L10n.resultNoteTitle, text: $memoText, prompt: Text(L10n.resultNotePrompt), axis: .vertical)
                .lineLimit(2...6)
                .focused($isNoteFocused)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onChange(of: memoText) { _, text in
                    if text.count > ScanRecord.noteLimit { memoText = String(text.prefix(ScanRecord.noteLimit)) }
                }
                .onChange(of: isNoteFocused) { _, focused in
                    if !focused { saveNote() }
                }
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.resultNoteFooter)
                Spacer(minLength: 8)
                Text(L10n.resultNoteCount(memoText.count, ScanRecord.noteLimit))
                    .monospacedDigit()
                    .accessibilityHidden(true)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    /// Writes the note to the history record (an empty note is stored as none).
    private func saveNote() {
        guard let id = result.recordID, let record = modelContext.model(for: id) as? ScanRecord else { return }
        let trimmed = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        let value: String? = trimmed.isEmpty ? nil : String(trimmed.prefix(ScanRecord.noteLimit))
        guard record.note != value else { return }
        record.note = value
        try? modelContext.save()
    }

    private func toggleFavorite() {
        guard let id = result.recordID, let record = modelContext.model(for: id) as? ScanRecord else { return }
        record.isFavorite.toggle()
        try? modelContext.save()
        isFavorite = record.isFavorite
    }
}

struct ResultAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// Grouped card holding rows separated by dividers.
struct ResultCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Title / value row. Values are never truncated; at accessibility sizes the row stacks vertically.
struct ResultRow: View {
    let title: String
    let value: String
    var systemImage: String?

    var body: some View {
        AdaptiveStack(spacing: 4, alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                Text(value)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Lays children out horizontally, switching to a vertical stack at accessibility text sizes
/// (HIG Typography: inline items stack when text is very large).
struct AdaptiveStack<Content: View>: View {
    var spacing: CGFloat = 8
    var alignment: VerticalAlignment = .center
    @ViewBuilder let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) { content }
        } else {
            HStack(alignment: alignment, spacing: spacing) { content }
        }
    }
}

/// A note about a URL, shown above its details (docs/design/16_url_check.svg). Warnings are red, cautions amber.
struct URLRiskCard: View {
    let risk: URLRisk
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: risk.severity == .warning ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        risk.severity == .warning ? Color(.systemRed) : Color(.systemOrange)
    }
}
