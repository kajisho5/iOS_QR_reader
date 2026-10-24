import PhotosUI
import StoreKit
import SwiftData
import SwiftUI
import UIKit

/// The first screen: scanning starts immediately, with no splash or tutorial.
/// Compact width shows results in a sheet and puts the scan controls at the bottom, within thumb
/// reach; regular width (iPad, iPhone Duo inner display) shows results in a pane beside the camera
/// and the controls in the toolbar.
struct ScannerView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isProUnlocked) private var isPro
    @Environment(\.requestReview) private var requestReview

    @State private var capture = CaptureController()
    @State private var coordinator = ScanCoordinator()
    @State private var isVisible = false
    @State private var isPhotoPickerPresented = false
    @State private var photoItem: PhotosPickerItem?
    @State private var imageAlert: ImageAlert?
    @State private var multipleCodes: [DetectedCode] = []
    /// A contact to add after the result sheet has closed (one sheet at a time: HIG Sheets).
    @State private var pendingContact: ContactCard?
    @State private var contactToAdd: ContactRequest?

    private var presentsSheet: Bool { horizontalSizeClass != .regular }
    /// iPhone Duo outer display (and other vertical-bar contexts): the system lays toolbars out
    /// vertically on the trailing edge (HIG "Designing for iPhone Duo"), so the scan controls stay
    /// in the toolbar there instead of the bottom row.
    @State private var hasVerticalBar = false
    /// Where the person tapped to focus (preview coordinates); shown briefly as a square.
    @State private var focusIndicator: FocusTap?
    private var showsBottomControls: Bool { presentsSheet && !hasVerticalBar }

    var body: some View {
        NavigationStack {
            Group {
                if presentsSheet {
                    cameraArea
                } else {
                    regularLayout
                }
            }
            .toolbar {
                if !showsBottomControls { toolbarContent }
            }
            .toolbar(showsBottomControls ? .hidden : .automatic, for: .navigationBar)
            .toolbarColorScheme(presentsSheet && hasVerticalBar ? .dark : nil, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .detectsVerticalToolbar($hasVerticalBar)
        .onAppear {
            isVisible = true
            updateCoordinator()
            startCamera()
        }
        .onChange(of: horizontalSizeClass) { updateCoordinator() }
        .onChange(of: isPro) { updateCoordinator() }
        .onDisappear {
            isVisible = false
            // Kept running briefly, so going to another tab and straight back shows the camera at once.
            capture.stop(after: .seconds(3))
            requestReviewIfDue()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { startCamera() } else if phase == .background { capture.stop() }
        }
        .onChange(of: coordinator.presented == nil) { _, isClosed in
            // The camera keeps running behind the result sheet, so it is live again the moment the
            // sheet closes. The coordinator ignores codes while the sheet is open, and the code just
            // shown for 2 seconds after it closes.
            if isClosed {
                startCamera()
                requestReviewIfDue()
            }
        }
        .onChange(of: coordinator.isContinuous) { _, isOn in
            if !isOn { requestReviewIfDue() }
        }
        .sheet(item: $coordinator.presented, onDismiss: showPendingContact) { result in
            NavigationStack {
                ResultView(result: result, addContact: addContactAfterClosing)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                coordinator.presented = nil
                            } label: {
                                Label(L10n.commonClose, systemImage: "xmark")
                            }
                            .keyboardShortcut(.cancelAction)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents(resultDetents)
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $contactToAdd) { request in
            ContactAddView(card: request.card) { contactToAdd = nil }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await readPhoto(item) }
        }
        .alert(imageAlert?.title ?? "", isPresented: isImageAlertPresented, presenting: imageAlert) { alert in
            Button(L10n.commonCancel, role: .cancel) {}
            if alert == .noCode {
                Button(L10n.scanNoCodeRetry) { isPhotoPickerPresented = true }
            }
        } message: { alert in
            Text(alert.message)
        }
        .confirmationDialog(L10n.scanMultipleCodesTitle, isPresented: isChoosingCode, titleVisibility: .visible) {
            ForEach(multipleCodes, id: \.self) { code in
                Button(choiceTitle(for: code)) { handle(code, source: .photo) }
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.scanMultipleCodesMessage)
        }
    }

    // MARK: Layout

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var resultDetents: Set<PresentationDetent> {
        dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large]
    }

    /// Camera | result. On iOS 27.1+ an ArrangementView splits them and keeps each side clear of
    /// the fold when iPhone Duo is partially folded (HIG "Designing for iPhone Duo").
    /// The ArrangementView API needs the iOS 27.1 SDK (Xcode 27.1, Swift 6.4); older SDKs use the
    /// stack layout below.
    @ViewBuilder
    private var regularLayout: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            ArrangementView {
                cameraArea
                    .splitArrangementLayoutRatio(0.58)
            } secondary: {
                resultPane
            }
            .arrangementViewStyle(.split)
        } else {
            stackedRegularLayout
        }
        #else
        stackedRegularLayout
        #endif
    }

    /// One layout whose axis follows the shape, so rotating keeps the same camera view (separate
    /// HStack / VStack branches would rebuild the preview on every rotation).
    private var stackedRegularLayout: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= proxy.size.height
            let layout = isWide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                cameraArea
                    .frame(height: isWide ? nil : proxy.size.height * 0.5)
                Divider()
                resultPane
                    .frame(width: isWide ? min(420, proxy.size.width * 0.42) : nil)
            }
        }
    }

    @ViewBuilder
    private var resultPane: some View {
        if let latest = coordinator.latest {
            ResultView(result: latest, style: .pane)
        } else {
            ContentUnavailableView(
                L10n.scanPaneEmptyTitle,
                systemImage: "qrcode.viewfinder",
                description: Text(L10n.scanPaneEmptyMessage)
            )
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private var cameraArea: some View {
        switch capture.state {
        case .denied:
            CameraStatusView(reason: .denied, onPickPhoto: pickPhoto)
        case .restricted:
            CameraStatusView(reason: .restricted, onPickPhoto: pickPhoto)
        case .unavailable:
            CameraStatusView(reason: .unavailable, onPickPhoto: pickPhoto)
        case .interruptedByMultitasking:
            CameraStatusView(reason: .multitasking, onPickPhoto: pickPhoto)
        case .idle, .starting, .running:
            liveCamera
        }
    }

    private var liveCamera: some View {
        ZStack {
            Group {
                Color.black
                CameraPreview(
                    session: capture.session,
                    device: capture.device,
                    zoomFactor: capture.zoomFactor,
                    zoomValueText: zoomText,
                    onZoom: { capture.setZoom($0) },
                    onZoomStep: { capture.stepZoom(in: $0) },
                    onResetZoom: { capture.resetZoom() },
                    onFocus: { devicePoint, viewPoint in
                        capture.focus(atDevicePoint: devicePoint)
                        focusIndicator = FocusTap(point: viewPoint)
                    }
                )
                .overlay(alignment: .topLeading) {
                    if let focusIndicator {
                        FocusSquare()
                            .position(focusIndicator.point)
                            .id(focusIndicator.id)
                            .task(id: focusIndicator.id) {
                                try? await Task.sleep(for: .seconds(1.2))
                                if self.focusIndicator?.id == focusIndicator.id { self.focusIndicator = nil }
                            }
                    }
                }
                ReticleOverlay(isActive: coordinator.isContinuous, isRaised: isTrayVisible && presentsSheet)
            }
            .ignoresSafeArea(edges: [.top, .horizontal])
            VStack(spacing: 12) {
                if presentsSheet {
                    // Top of the screen: information only, no controls.
                    NoticeCapsule(text: L10n.scanPrivacyNote, systemImage: "checkmark.shield")
                        .padding(.top, 8)
                }
                Spacer()
                if coordinator.isToastVisible {
                    NoticeCapsule(text: L10n.scanDetectedToast, systemImage: "checkmark.circle.fill", prominent: true)
                        .transition(.opacity)
                }
                if isTrayVisible {
                    ContinuousTray(
                        results: coordinator.tray,
                        onSelect: { coordinator.show($0) },
                        onEnd: { coordinator.setContinuous(false) }
                    )
                } else {
                    VStack(spacing: 4) {
                        Text(L10n.scanHint)
                            .font(.headline)
                        Text(L10n.scanSupported)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                    if !presentsSheet {
                        NoticeCapsule(text: L10n.scanPrivacyNote, systemImage: "checkmark.shield")
                    }
                }
                if isZoomed {
                    Button {
                        capture.resetZoom()
                    } label: {
                        NoticeCapsule(text: zoomText, systemImage: "plus.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(zoomText)
                    .accessibilityHint(L10n.scanZoomReset)
                }
                if showsBottomControls {
                    controlBar
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .animation(.default, value: coordinator.isToastVisible)
        }
        .environment(\.colorScheme, .dark)
    }

    private var zoomText: String {
        L10n.scanZoomValue(Double(capture.displayZoom).formatted(.number.precision(.fractionLength(1))))
    }

    private var isZoomed: Bool {
        capture.state == .running && abs(capture.displayZoom - 1) > 0.05
    }

    private var isTrayVisible: Bool { coordinator.isContinuous && !coordinator.tray.isEmpty }

    // MARK: Bottom controls (compact width)

    private var controlBar: some View {
        HStack(alignment: .top, spacing: 8) {
            ScanControlButton(
                title: L10n.scanControlPhoto,
                systemImage: "photo",
                accessibilityLabel: L10n.scanPhoto,
                action: pickPhoto
            )
            .keyboardShortcut("o", modifiers: .command)
            ScanControlButton(
                title: coordinator.isContinuous ? L10n.scanControlContinuousOn : L10n.scanContinuous,
                systemImage: "repeat",
                isOn: coordinator.isContinuous,
                accessibilityLabel: L10n.scanContinuous,
                accessibilityValue: coordinator.isContinuous ? L10n.commonOn : L10n.commonOff
            ) {
                coordinator.setContinuous(!coordinator.isContinuous)
            }
            if capture.hasTorch && capture.state == .running {
                ScanControlButton(
                    title: L10n.scanTorch,
                    systemImage: capture.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                    isOn: capture.isTorchOn,
                    accessibilityLabel: L10n.scanTorch,
                    accessibilityValue: capture.isTorchOn ? L10n.commonOn : L10n.commonOff
                ) {
                    Task { await capture.toggleTorch() }
                }
            }
        }
        .frame(maxWidth: 420)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                coordinator.setContinuous(!coordinator.isContinuous)
            } label: {
                Label(coordinator.isContinuous ? L10n.scanContinuousOn : L10n.scanContinuous, systemImage: "repeat")
                    .labelStyle(.titleAndIcon)
            }
            .tint(coordinator.isContinuous ? AppColor.accentOnCamera : nil)
            .accessibilityLabel(L10n.scanContinuous)
            .accessibilityValue(coordinator.isContinuous ? L10n.commonOn : L10n.commonOff)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: pickPhoto) {
                Label(L10n.scanPhoto, systemImage: "photo")
            }
            .keyboardShortcut("o", modifiers: .command)
            if capture.hasTorch && capture.state == .running {
                Button {
                    Task { await capture.toggleTorch() }
                } label: {
                    Label(L10n.scanTorch, systemImage: capture.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                }
                .accessibilityValue(capture.isTorchOn ? L10n.commonOn : L10n.commonOff)
            }
        }
    }

    // MARK: Actions

    private func startCamera() {
        guard isVisible, scenePhase == .active else { return }
        coordinator.feedback.prepare()
        let coordinator = coordinator
        Task {
            await capture.start { code in coordinator.handle(code, source: .camera) }
        }
    }

    /// Asks for a rating at a pause (a result was closed, continuous scanning ended, or the
    /// scan screen was left), at most once, and only after more than ten successful scans.
    private func requestReviewIfDue() {
        guard ReviewPromptPolicy.shouldRequest(successfulScans: settings.successfulScans, alreadyRequested: settings.hasRequestedReview) else { return }
        settings.hasRequestedReview = true
        Task {
            // Let the sheet finish dismissing so the system prompt is not presented over it.
            try? await Task.sleep(for: .seconds(0.6))
            requestReview()
        }
    }

    /// Adding a contact from the result sheet closes the sheet first, then shows the contact form.
    private func addContactAfterClosing(_ card: ContactCard) {
        pendingContact = card
        coordinator.presented = nil
    }

    private func showPendingContact() {
        guard let card = pendingContact else { return }
        pendingContact = nil
        contactToAdd = ContactRequest(card: card)
    }

    private func updateCoordinator() {
        coordinator.update(.init(settings: settings, context: modelContext, isPro: isPro, presentsSheet: presentsSheet))
    }

    private func handle(_ code: DetectedCode, source: RecordSource) {
        coordinator.handle(code, source: source)
    }

    private func pickPhoto() {
        isPhotoPickerPresented = true
    }

    private func readPhoto(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            imageAlert = .loadFailed
            return
        }
        let codes = (try? await ImageCodeReader.detect(in: image)) ?? []
        switch codes.count {
        case 0: imageAlert = .noCode
        case 1: handle(codes[0], source: .photo)
        default: multipleCodes = codes
        }
    }

    private func choiceTitle(for code: DetectedCode) -> String {
        let kind = PayloadParser.parse(code.content).kind.title
        let preview = code.content.count > 40 ? String(code.content.prefix(40)) + "…" : code.content
        return "\(kind)\(L10n.metaSeparator)\(preview)"
    }

    private var isImageAlertPresented: Binding<Bool> {
        Binding(get: { imageAlert != nil }, set: { if !$0 { imageAlert = nil } })
    }

    private var isChoosingCode: Binding<Bool> {
        Binding(get: { !multipleCodes.isEmpty }, set: { if !$0 { multipleCodes = [] } })
    }
}

private enum ImageAlert: Equatable {
    case noCode
    case loadFailed

    var title: String {
        switch self {
        case .noCode: L10n.scanNoCodeTitle
        case .loadFailed: L10n.scanImageLoadFailedTitle
        }
    }

    var message: String {
        switch self {
        case .noCode: L10n.scanNoCodeMessage
        case .loadFailed: L10n.scanImageLoadFailedMessage
        }
    }
}

/// Round control under the camera (compact width): icon in a circle with a short label below.
private struct ScanControlButton: View {
    let title: String
    let systemImage: String
    var isOn = false
    let accessibilityLabel: String
    var accessibilityValue: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isOn ? Color.black : Color.white)
                    .frame(width: 56, height: 56)
                    .background {
                        if isOn {
                            Circle().fill(Color.white)
                        } else {
                            Circle().fill(.ultraThinMaterial)
                        }
                    }
                    .overlay { Circle().strokeBorder(Color.white.opacity(isOn ? 0 : 0.3)) }
                    .contentShape(.hoverEffect, Circle())
                    .hoverEffect(.lift)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "")
    }
}

private extension View {
    /// Sets `hasVerticalBar` when the system places toolbars in a vertical bar (iOS 27.1+).
    @ViewBuilder
    func detectsVerticalToolbar(_ hasVerticalBar: Binding<Bool>) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            modifier(VerticalToolbarProbe(hasVerticalBar: hasVerticalBar))
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if compiler(>=6.4)
@available(iOS 27.1, *)
private struct VerticalToolbarProbe: ViewModifier {
    @Environment(\.toolbarVerticalEdge) private var edge
    @Binding var hasVerticalBar: Bool

    func body(content: Content) -> some View {
        content.onChange(of: edge, initial: true) { _, edge in
            hasVerticalBar = edge != nil
        }
    }
}
#endif

private struct FocusTap: Equatable {
    let id = UUID()
    let point: CGPoint
}

/// Brief square at the tap-to-focus point. Decorative (VoiceOver users zoom instead).
private struct FocusSquare: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(AppColor.accentOnCamera, lineWidth: 2)
            .frame(width: 76, height: 76)
            .scaleEffect(settled ? 1 : 1.3)
            .opacity(settled ? 1 : 0.4)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { settled = true }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
