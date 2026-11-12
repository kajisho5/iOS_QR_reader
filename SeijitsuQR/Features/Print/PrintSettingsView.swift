import SwiftUI
import UIKit

/// Choose how to print a code, then open the iOS print screen (docs/design/27_print.svg J2).
struct PrintSettingsView: View {
    let image: UIImage
    /// Printed under the code: the network name or the domain, never a password.
    let caption: String

    @Environment(\.dismiss) private var dismiss
    @State private var options = PrintSheet.Options()
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.printLayout) {
                    Picker(L10n.printLayout, selection: $options.layout) {
                        Text(L10n.printLayoutSingle).tag(PrintSheet.Layout.single)
                        Text(L10n.printLayoutLabels).tag(PrintSheet.Layout.labels)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section {
                    Image(uiImage: PrintSheet.preview(image: image, caption: caption, options: options, width: 180))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 180)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                } footer: {
                    Text(options.layout == .labels ? L10n.printLabelsSummary : L10n.printPaperNote)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                Section {
                    if options.layout == .single {
                        Stepper(value: $options.sizeCentimeters, in: PrintSheet.Options.sizeRange) {
                            LabeledContent(L10n.printSize, value: L10n.printSizeValue(options.sizeCentimeters))
                        }
                    }
                    if !caption.isEmpty {
                        Toggle(L10n.printCaption, isOn: $options.showsCaption)
                            .tint(AppColor.accentFill)
                    }
                } footer: {
                    if !caption.isEmpty { Text(L10n.printCaptionNote(caption)) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: startPrinting) {
                    Label(L10n.printChoosePrinter, systemImage: "printer")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
            .navigationTitle(L10n.printTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(L10n.commonClose, systemImage: "xmark")
                    }
                }
            }
            .alert(L10n.printFailed, isPresented: $failed) {
                Button(L10n.commonClose, role: .cancel) {}
            }
        }
    }

    private func startPrinting() {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.jobName = caption.isEmpty ? L10n.printTitle : caption
        controller.printInfo = info
        controller.printingItem = PrintSheet.pdf(image: image, caption: options.showsCaption ? caption : "", options: options)
        let completion: UIPrintInteractionController.CompletionHandler = { _, _, error in
            guard error != nil else { return }
            Task { @MainActor in failed = true }
        }
        // iPad shows the print options as a popover, which needs an anchor.
        if UIDevice.current.userInterfaceIdiom == .pad,
           let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow) {
            let anchor = CGRect(x: window.bounds.midX, y: window.bounds.maxY - 80, width: 1, height: 1)
            controller.present(from: anchor, in: window, animated: true, completionHandler: completion)
        } else {
            controller.present(animated: true, completionHandler: completion)
        }
    }
}
