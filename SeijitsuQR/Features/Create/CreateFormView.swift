import SwiftData
import SwiftUI
import UIKit

/// Input form for one kind of QR code. The code is generated, and saved to history,
/// only when the user taps "QRコードを作成" (not on every keystroke).
struct CreateFormView: View {
    let kind: CreateKind

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isProUnlocked) private var isPro
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    @State private var form = FormState()
    @State private var generated: GeneratedCode?
    @State private var errorMessage: String?
    @State private var isSavingPhoto = false
    @State private var savedToPhotos = false
    @State private var photoAlert: PhotoAlert?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: 0) {
                    inputForm
                    Divider()
                    ScrollView {
                        preview.padding(20)
                    }
                    .frame(width: 400)
                    .background(Color(.systemGroupedBackground))
                }
            } else {
                inputForm
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: form) {
            generated = nil
            errorMessage = nil
            savedToPhotos = false
        }
        .alert(photoAlert?.title ?? "", isPresented: isPhotoAlertPresented, presenting: photoAlert) { alert in
            Button(L10n.commonCancel, role: .cancel) {}
            if alert == .denied {
                Button(L10n.commonOpenSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } message: { alert in
            Text(alert.message)
        }
    }

    // MARK: Form

    private var inputForm: some View {
        Form {
            Section(L10n.createSectionInput) {
                fields
            }
            Section {
                Button(action: generate) {
                    Label(L10n.createGenerate, systemImage: "qrcode")
                }
                .buttonStyle(PrimaryButtonStyle())
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .listRowBackground(Color.clear)
                }
            }
            if horizontalSizeClass != .regular, generated != nil {
                Section(L10n.createSectionPreview) {
                    preview
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }
            }
        }
    }

    @ViewBuilder
    private var fields: some View {
        switch kind {
        case .text:
            LabeledField(L10n.createFieldText) {
                TextField(L10n.createFieldText, text: $form.text, prompt: Text(L10n.createFieldTextPrompt), axis: .vertical)
                    .lineLimit(3...10)
            }
        case .url:
            LabeledField(L10n.createFieldUrl) {
                TextField(L10n.createFieldUrl, text: $form.url, prompt: Text(L10n.createFieldUrlPrompt))
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        case .wifi:
            LabeledField(L10n.createFieldSsid) {
                TextField(L10n.createFieldSsid, text: $form.wifi.ssid, prompt: Text(L10n.createFieldSsidPrompt))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Picker(L10n.createFieldSecurity, selection: $form.wifi.security) {
                Text(L10n.resultWifiSecurityWpa).tag(WiFiNetwork.Security.wpa)
                Text(L10n.resultWifiSecurityWep).tag(WiFiNetwork.Security.wep)
                Text(L10n.resultWifiSecurityOpen).tag(WiFiNetwork.Security.open)
            }
            if form.wifi.security != .open {
                LabeledField(L10n.createFieldPassword) {
                    SecureField(L10n.createFieldPassword, text: $form.wifi.password)
                        .textContentType(.password)
                }
            }
            Toggle(L10n.createFieldHidden, isOn: $form.wifi.isHidden)
                .tint(AppColor.accentFill)
        case .contact:
            LabeledField(L10n.createFieldFamilyName) {
                TextField(L10n.createFieldFamilyName, text: $form.contact.familyName).textContentType(.familyName)
            }
            LabeledField(L10n.createFieldGivenName) {
                TextField(L10n.createFieldGivenName, text: $form.contact.givenName).textContentType(.givenName)
            }
            LabeledField(L10n.createFieldOrganization) {
                TextField(L10n.createFieldOrganization, text: $form.contact.organization).textContentType(.organizationName)
            }
            LabeledField(L10n.createFieldJobTitle) {
                TextField(L10n.createFieldJobTitle, text: $form.contact.jobTitle).textContentType(.jobTitle)
            }
            LabeledField(L10n.createFieldPhone) {
                TextField(L10n.createFieldPhone, text: $form.contact.phone).keyboardType(.phonePad).textContentType(.telephoneNumber)
            }
            LabeledField(L10n.createFieldEmail) {
                TextField(L10n.createFieldEmail, text: $form.contact.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            LabeledField(L10n.createFieldUrlContact) {
                TextField(L10n.createFieldUrlContact, text: $form.contact.url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            LabeledField(L10n.createFieldAddress) {
                TextField(L10n.createFieldAddress, text: $form.contact.address, axis: .vertical).textContentType(.fullStreetAddress)
            }
            LabeledField(L10n.createFieldNote) {
                TextField(L10n.createFieldNote, text: $form.contact.note, axis: .vertical)
            }
        case .event:
            LabeledField(L10n.createFieldEventTitle) {
                TextField(L10n.createFieldEventTitle, text: $form.event.title)
            }
            LabeledField(L10n.createFieldLocation) {
                TextField(L10n.createFieldLocation, text: $form.event.location)
            }
            Toggle(L10n.createFieldAllDay, isOn: $form.event.isAllDay)
                .tint(AppColor.accentFill)
            DatePicker(L10n.createFieldStart, selection: $form.event.start, displayedComponents: form.event.isAllDay ? [.date] : [.date, .hourAndMinute])
            DatePicker(L10n.createFieldEnd, selection: $form.event.end, in: form.event.start..., displayedComponents: form.event.isAllDay ? [.date] : [.date, .hourAndMinute])
            LabeledField(L10n.createFieldNotes) {
                TextField(L10n.createFieldNotes, text: $form.event.notes, axis: .vertical)
            }
        }
    }

    // MARK: Preview

    @ViewBuilder
    private var preview: some View {
        if let generated {
            VStack(spacing: 14) {
                Image(uiImage: generated.image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel(L10n.createImageA11y)
                    .accessibilityValue(generated.content)
                Text(generated.content)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .lineLimit(6)
                if generated.isSaved {
                    Label(L10n.resultSaved, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    saveToPhotos(generated.image)
                } label: {
                    Label(savedToPhotos ? L10n.createSavedToPhotos : L10n.createSaveToPhotos, systemImage: savedToPhotos ? "checkmark" : "square.and.arrow.down")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSavingPhoto || savedToPhotos)
                ShareLink(item: Image(uiImage: generated.image), preview: SharePreview(kind.title, image: Image(uiImage: generated.image))) {
                    Label(L10n.commonShare, systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .foregroundStyle(Color.accentColor)
            }
            .frame(maxWidth: .infinity)
        } else {
            ContentUnavailableView(L10n.createSectionPreview, systemImage: "qrcode", description: Text(L10n.createPreviewEmpty))
        }
    }

    // MARK: Actions

    private func generate() {
        guard let content = encodedContent() else {
            errorMessage = invalidMessage
            return
        }
        guard let image = QRCodeRenderer.image(for: content) else {
            errorMessage = L10n.createTooLong
            return
        }
        var isSaved = false
        if settings.isAutosaveEnabled {
            let draft = RecordDraft(content: content, kind: kind.payloadKind, symbology: .qr, source: .created)
            isSaved = (try? HistoryRecorder(context: modelContext).record(draft, isPro: isPro)) != nil
        }
        errorMessage = nil
        savedToPhotos = false
        generated = GeneratedCode(content: content, image: image, isSaved: isSaved)
    }

    private func encodedContent() -> String? {
        switch kind {
        case .text: PayloadEncoder.text(form.text)
        case .url: PayloadEncoder.url(form.url)
        case .wifi: PayloadEncoder.wifi(form.wifi)
        case .contact: PayloadEncoder.contact(form.contact)
        case .event: PayloadEncoder.event(form.event)
        }
    }

    private var invalidMessage: String {
        switch kind {
        case .text: L10n.createInvalidText
        case .url: L10n.createInvalidUrl
        case .wifi: L10n.createInvalidWifi
        case .contact: L10n.createInvalidContact
        case .event: L10n.createInvalidEvent
        }
    }

    private func saveToPhotos(_ image: UIImage) {
        isSavingPhoto = true
        Task {
            let outcome = await PhotoLibrarySaver.save(image)
            isSavingPhoto = false
            switch outcome {
            case .saved:
                savedToPhotos = true
                AccessibilityNotification.Announcement(L10n.createSavedToPhotos).post()
            case .denied:
                photoAlert = .denied
            case .failed:
                photoAlert = .failed
            }
        }
    }

    private var isPhotoAlertPresented: Binding<Bool> {
        Binding(get: { photoAlert != nil }, set: { if !$0 { photoAlert = nil } })
    }
}

private struct FormState: Equatable {
    var text = ""
    var url = ""
    var wifi = WiFiDraft()
    var contact = ContactDraft()
    var event: EventDraft = {
        let calendar = Calendar.current
        let nextHour = calendar.nextDate(after: .now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? .now
        return EventDraft(start: nextHour, end: nextHour.addingTimeInterval(3600))
    }()
}

private struct GeneratedCode: Equatable {
    let content: String
    let image: UIImage
    let isSaved: Bool
}

private enum PhotoAlert: Equatable {
    case denied
    case failed

    var title: String {
        switch self {
        case .denied: L10n.createPhotoDeniedTitle
        case .failed: L10n.createPhotoFailedTitle
        }
    }

    var message: String {
        switch self {
        case .denied: L10n.createPhotoDeniedMessage
        case .failed: L10n.createPhotoFailedMessage
        }
    }
}

/// A visible label above its field (HIG: every field has a label, not just a placeholder).
private struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            content
        }
    }
}
