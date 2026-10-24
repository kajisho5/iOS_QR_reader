import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// The first screen: scanning starts immediately, with no splash or tutorial.
/// Compact width shows results in a sheet; regular width (iPad, iPhone Duo inner display)
/// shows them in a pane beside the camera.
struct ScannerView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isProUnlocked) private var isPro

    @State private var capture = CaptureController()
    @State private var coordinator = ScanCoordinator()
    @State private var isVisible = false
    @State private var isPhotoPickerPresented = false
    @State private var photoItem: PhotosPickerItem?
    @State private var imageAlert: ImageAlert?
    @State private var multipleCodes: [DetectedCode] = []

    private var presentsSheet: Bool { horizontalSizeClass != .regular }

    var body: some View {
        NavigationStack {
            Group {
                if presentsSheet {
                    cameraArea
                } else {
                    regularLayout
                }
            }
            .toolbar { toolbarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(isCameraLive && presentsSheet ? .dark : nil, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            isVisible = true
            updateCoordinator()
            startCamera()
        }
        .onChange(of: horizontalSizeClass) { updateCoordinator() }
        .onChange(of: isPro) { updateCoordinator() }
        .onDisappear {
            isVisible = false
            capture.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { startCamera() } else if phase == .background { capture.stop() }
        }
        .onChange(of: coordinator.presented == nil) { _, isClosed in
            // The camera pauses while a result sheet is open, so the same code is not read again.
            if isClosed { startCamera() } else { capture.stop() }
        }
        .sheet(item: $coordinator.presented) { result in
            NavigationStack {
                ResultView(result: result)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                coordinator.presented = nil
                            } label: {
                                Label(L10n.commonClose, systemImage: "xmark")
                            }
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents(resultDetents)
            .presentationDragIndicator(.visible)
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

    private var regularLayout: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= proxy.size.height
            if isWide {
                HStack(spacing: 0) {
                    cameraArea
                    Divider()
                    resultPane
                        .frame(width: min(420, proxy.size.width * 0.42))
                }
            } else {
                VStack(spacing: 0) {
                    cameraArea
                        .frame(height: proxy.size.height * 0.5)
                    Divider()
                    resultPane
                }
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
            Color.black
            CameraPreview(session: capture.session, device: capture.device)
            ReticleOverlay(isActive: coordinator.isContinuous)
            VStack(spacing: 12) {
                Spacer()
                if coordinator.isToastVisible {
                    NoticeCapsule(text: L10n.scanDetectedToast, systemImage: "checkmark.circle.fill", prominent: true)
                        .transition(.opacity)
                }
                if coordinator.isContinuous, !coordinator.tray.isEmpty {
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
                    NoticeCapsule(text: L10n.scanPrivacyNote, systemImage: "checkmark.shield")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .animation(.default, value: coordinator.isToastVisible)
        }
        .ignoresSafeArea(edges: [.top, .horizontal])
        .environment(\.colorScheme, .dark)
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
        guard isVisible, coordinator.presented == nil, scenePhase == .active else { return }
        coordinator.feedback.prepare()
        let coordinator = coordinator
        Task {
            await capture.start { code in coordinator.handle(code, source: .camera) }
        }
    }

    private func updateCoordinator() {
        coordinator.update(.init(settings: settings, context: modelContext, isPro: isPro, presentsSheet: presentsSheet))
    }

    private func handle(_ code: DetectedCode, source: RecordSource) {
        coordinator.handle(code, source: source)
    }

    private var isCameraLive: Bool {
        switch capture.state {
        case .idle, .starting, .running: true
        case .denied, .restricted, .unavailable, .interruptedByMultitasking: false
        }
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
