import SwiftUI
import UIKit

/// A scanned code drawn again, full screen (docs/design/15_show_code.svg A2). White in both appearances
/// so any scanner can read it, with the screen at full brightness while it is shown.
struct CodeDisplayView: View {
    let image: UIImage
    let title: String
    let subtitle: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var savedBrightness: CGFloat?
    @State private var isSaving = false
    @State private var saved = false
    @State private var alert: ResultAlert?
    @State private var isPrinting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 520)
                        .padding(12)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.08))
                        }
                        .accessibilityLabel(L10n.codeDisplayImage(title))

                    Label(L10n.codeDisplayBrightness, systemImage: "sun.max.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.04, green: 0.37, blue: 0.31))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.89, green: 0.95, blue: 0.93), in: Capsule())

                    Text(L10n.codeDisplayNote)
                        .font(.footnote)
                        .foregroundStyle(Color(white: 0.42))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: save) {
                        Label(saved ? L10n.createSavedToPhotos : L10n.createSaveToPhotos, systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSaving || saved)

                    HStack(spacing: 12) {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview(title, image: Image(uiImage: image))) {
                            Label(L10n.codeDisplayShareImage, systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        Button {
                            isPrinting = true
                        } label: {
                            Label(L10n.printButton, systemImage: "printer")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .keyboardShortcut("p", modifiers: .command)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.ignoresSafeArea())
            }
            .background(Color.white.ignoresSafeArea())
            .environment(\.colorScheme, .light)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(title).font(.headline).lineLimit(1)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(L10n.commonClose, systemImage: "xmark")
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .sheet(isPresented: $isPrinting) {
            // The title is the network name or the domain (never a password): ResultView.codeTitle.
            // Other kinds only have their kind name as the title, which is not worth printing.
            PrintSettingsView(image: image, caption: title == subtitle ? "" : title)
        }
        .onAppear(perform: raiseBrightness)
        .onDisappear(perform: restoreBrightness)
        .onChange(of: scenePhase) { _, phase in
            // Give the brightness back while the app is in the background.
            if phase == .active { raiseBrightness() } else { restoreBrightness() }
        }
        .alert(alert?.title ?? "", isPresented: isAlertPresented, presenting: alert) { _ in
            Button(L10n.commonClose, role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    private func raiseBrightness() {
        guard let screen, savedBrightness == nil else { return }
        savedBrightness = screen.brightness
        screen.brightness = 1
    }

    private func restoreBrightness() {
        guard let screen, let savedBrightness else { return }
        screen.brightness = savedBrightness
        self.savedBrightness = nil
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })
    }

    private func save() {
        isSaving = true
        Task {
            let outcome = await PhotoLibrarySaver.save(image)
            isSaving = false
            switch outcome {
            case .saved:
                saved = true
                AccessibilityNotification.Announcement(L10n.createSavedToPhotos).post()
            case .denied:
                alert = ResultAlert(title: L10n.createPhotoDeniedTitle, message: L10n.createPhotoDeniedMessage)
            case .failed:
                alert = ResultAlert(title: L10n.createPhotoFailedTitle, message: L10n.createPhotoFailedMessage)
            }
        }
    }
}
