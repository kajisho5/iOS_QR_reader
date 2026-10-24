@preconcurrency import AVFoundation
import SwiftUI
import UIKit

/// Live camera preview. On iPad the preview stays level as the device rotates
/// (AVCaptureDevice.RotationCoordinator); iPhone is portrait-only.
/// Gestures: pinch to zoom, tap to focus, double-tap to return to 1×.
/// VoiceOver: the preview is adjustable (swipe up/down to zoom).
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let device: AVCaptureDevice?
    var zoomFactor: CGFloat = 1
    var zoomValueText = ""
    var onZoom: (CGFloat) -> Void = { _ in }
    var onZoomStep: (Bool) -> Void = { _ in }
    var onResetZoom: () -> Void = {}
    /// Device point for focusing, and the tapped point in the view (for the focus indicator).
    var onFocus: (CGPoint, CGPoint) -> Void = { _, _ in }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.isAccessibilityElement = true
        view.accessibilityLabel = L10n.scanPreview
        view.accessibilityHint = L10n.scanPreviewHint
        view.accessibilityTraits = [.image, .adjustable]
        return view
    }

    /// Lets go of the session as soon as SwiftUI drops this preview, so a preview created in its
    /// place (e.g. after a layout change) is not left waiting behind the old layer's connection.
    static func dismantleUIView(_ view: PreviewView, coordinator: ()) {
        view.previewLayer.session = nil
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.attach(device: device)
        view.zoomFactor = zoomFactor
        view.onZoom = onZoom
        view.onZoomStep = onZoomStep
        view.onResetZoom = onResetZoom
        view.onFocus = onFocus
        view.accessibilityValue = zoomValueText
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    // The layer class is fixed above, so this cast always succeeds.
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    var zoomFactor: CGFloat = 1
    var onZoom: (CGFloat) -> Void = { _ in }
    var onZoomStep: (Bool) -> Void = { _ in }
    var onResetZoom: () -> Void = {}
    var onFocus: (CGPoint, CGPoint) -> Void = { _, _ in }

    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var pinchStartZoom: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: doubleTap)
        [pinch, doubleTap, tap].forEach(addGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func attach(device: AVCaptureDevice?) {
        guard let device, rotationCoordinator?.device !== device else { return }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        applyRotation(coordinator.videoRotationAngleForHorizonLevelPreview)
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            Task { @MainActor in self?.applyRotation(angle) }
        }
    }

    private func applyRotation(_ angle: CGFloat) {
        guard let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            pinchStartZoom = zoomFactor
        case .changed:
            onZoom(pinchStartZoom * gesture.scale)
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        onFocus(previewLayer.captureDevicePointConverted(fromLayerPoint: point), point)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        onResetZoom()
    }

    override func accessibilityIncrement() {
        onZoomStep(true)
    }

    override func accessibilityDecrement() {
        onZoomStep(false)
    }
}
