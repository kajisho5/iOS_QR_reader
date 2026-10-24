@preconcurrency import AVFoundation

/// A code read by the camera or from an image.
struct DetectedCode: Equatable, Hashable, Sendable {
    let content: String
    let symbology: CodeSymbology

    var dedupeKey: String { "\(symbology.rawValue)|\(content)" }
}

extension CodeSymbology {
    init?(objectType: AVMetadataObject.ObjectType) {
        switch objectType {
        case .qr: self = .qr
        case .ean13: self = .ean13
        case .ean8: self = .ean8
        case .upce: self = .upce
        case .code39: self = .code39
        case .code93: self = .code93
        case .code128: self = .code128
        case .itf14: self = .itf14
        case .pdf417: self = .pdf417
        case .aztec: self = .aztec
        case .dataMatrix: self = .dataMatrix
        default: return nil
        }
    }

    var objectType: AVMetadataObject.ObjectType {
        switch self {
        case .qr: .qr
        case .ean13: .ean13
        case .ean8: .ean8
        case .upce: .upce
        case .code39: .code39
        case .code93: .code93
        case .code128: .code128
        case .itf14: .itf14
        case .pdf417: .pdf417
        case .aztec: .aztec
        case .dataMatrix: .dataMatrix
        }
    }
}

/// Converts between the device's zoom factor and the factor shown to people (1× = the wide lens,
/// as in the Camera app).
enum CameraZoom {
    /// Multiply the device factor by this to get the displayed factor.
    static func displayMultiplier(for device: AVCaptureDevice) -> CGFloat {
        if #available(iOS 18.0, *) {
            return device.displayVideoZoomFactorMultiplier
        }
        // Before iOS 18: an ultra wide first constituent means the wide lens starts at the
        // first switch-over factor.
        if device.constituentDevices.first?.deviceType == .builtInUltraWideCamera,
           let first = device.virtualDeviceSwitchOverVideoZoomFactors.first?.doubleValue, first > 0 {
            return 1 / CGFloat(first)
        }
        return 1
    }

    /// Device factor that is displayed as 1×.
    static func standardFactor(for device: AVCaptureDevice) -> CGFloat {
        1 / displayMultiplier(for: device)
    }

    /// The largest factor offered to people: 10× (displayed), or less if the device can't.
    static func maximumFactor(for device: AVCaptureDevice) -> CGFloat {
        min(device.maxAvailableVideoZoomFactor, standardFactor(for: device) * 10)
    }
}

/// Wraps a capture device so it can be handed from the session queue to the main actor.
/// The device is only read on the main actor (rotation coordinator) after configuration.
struct CaptureDeviceReference: @unchecked Sendable {
    let device: AVCaptureDevice
}

/// Owns the AVCaptureSession. Every session mutation happens on `queue`.
final class CaptureEngine: NSObject, @unchecked Sendable {
    enum StartResult: Sendable {
        case running(CaptureDeviceReference)
        case noCamera
        case failed
    }

    /// One engine for the app, so the camera can be started at launch (`prewarm()`), before the
    /// scan screen asks for it.
    static let shared = CaptureEngine()

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "SeijitsuQR.capture")
    private let metadataOutput = AVCaptureMetadataOutput()
    private var device: AVCaptureDevice?
    private var isConfigured = false
    private var handler: (@Sendable (DetectedCode) -> Void)?

    func start(onDetect: @escaping @Sendable (DetectedCode) -> Void) async -> StartResult {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.startOnQueue(onDetect: onDetect))
            }
        }
    }

    /// Configures and starts the camera on the session queue without waiting, so it runs alongside
    /// the rest of app launch. Codes are ignored until `start(onDetect:)` sets a handler. Only call
    /// this when camera access is already granted (it must not trigger the permission prompt).
    func prewarm() {
        queue.async {
            if !self.isConfigured {
                guard case .running = self.configure() else { return }
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    /// Sets the zoom factor (device units, clamped to what the device allows).
    func setZoom(_ factor: CGFloat) {
        queue.async {
            guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
            device.videoZoomFactor = min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
            device.unlockForConfiguration()
        }
    }

    /// Focuses (and meters exposure) once at a point in device coordinates ({0,0} top-left,
    /// {1,1} bottom-right of the unrotated image). Continuous autofocus resumes when the
    /// subject area changes (see `resumeContinuousFocus`).
    func focus(at devicePoint: CGPoint) {
        queue.async {
            guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }
    }

    /// Back to continuous autofocus on the center (after a tap-to-focus, once the scene changes).
    func resumeContinuousFocus() {
        queue.async {
            guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
            let center = CGPoint(x: 0.5, y: 0.5)
            if device.isFocusPointOfInterestSupported { device.focusPointOfInterest = center }
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposurePointOfInterestSupported { device.exposurePointOfInterest = center }
            device.unlockForConfiguration()
        }
    }

    /// Returns the torch state actually applied.
    func setTorch(_ isOn: Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async {
                guard let device = self.device, device.hasTorch, device.isTorchAvailable else {
                    continuation.resume(returning: false)
                    return
                }
                do {
                    try device.lockForConfiguration()
                    device.torchMode = isOn ? .on : .off
                    device.unlockForConfiguration()
                    continuation.resume(returning: isOn)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func startOnQueue(onDetect: @escaping @Sendable (DetectedCode) -> Void) -> StartResult {
        handler = onDetect
        if !isConfigured {
            guard let result = configure() else { return .failed }
            if case .noCamera = result { return .noCamera }
        }
        if !session.isRunning {
            session.startRunning()
        }
        guard let device else { return .noCamera }
        return .running(CaptureDeviceReference(device: device))
    }

    /// Returns nil when configuration failed, `.noCamera` when no back camera exists.
    private func configure() -> StartResult? {
        // Virtual multi-camera devices switch lenses for close focus, which helps small codes.
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        guard let camera = discovery.devices.first ?? AVCaptureDevice.default(for: .video) else {
            return .noCamera
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }
        guard let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) else {
            return nil
        }
        session.addInput(input)
        guard session.canAddOutput(metadataOutput) else { return nil }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
        let wanted = CodeSymbology.allCases.map(\.objectType)
        metadataOutput.metadataObjectTypes = wanted.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }

        // Keep scanning while other apps share the screen, where the system allows it.
        if session.isMultitaskingCameraAccessSupported {
            session.isMultitaskingCameraAccessEnabled = true
        }
        if (try? camera.lockForConfiguration()) != nil {
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            // No focus range restriction: `.near` speeds up close codes but keeps far ones (a poster
            // across the room, a code read with zoom) from coming into focus. Close codes still get
            // the macro lens switch of multi-camera devices.
            if camera.isAutoFocusRangeRestrictionSupported {
                camera.autoFocusRangeRestriction = .none
            }
            // Lets the app return to continuous autofocus after a tap-to-focus.
            camera.isSubjectAreaChangeMonitoringEnabled = true
            // Virtual devices with an ultra wide lens start at its full field of view (zoom 1.0,
            // shown as 0.5× in the Camera app). Start at the wide lens instead, like the Camera
            // app's 1×; the device still switches lenses for close focus.
            camera.videoZoomFactor = min(max(CameraZoom.standardFactor(for: camera), camera.minAvailableVideoZoomFactor), camera.maxAvailableVideoZoomFactor)
            camera.unlockForConfiguration()
        }
        device = camera
        isConfigured = true
        return .running(CaptureDeviceReference(device: camera))
    }
}

extension CaptureEngine: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for object in metadataObjects {
            guard let code = object as? AVMetadataMachineReadableCodeObject,
                  let value = code.stringValue, !value.isEmpty,
                  let symbology = CodeSymbology(objectType: code.type)
            else { continue }
            handler?(DetectedCode(content: value, symbology: symbology))
            return
        }
    }
}
