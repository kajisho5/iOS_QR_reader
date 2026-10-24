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

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
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
            if camera.isAutoFocusRangeRestrictionSupported {
                camera.autoFocusRangeRestriction = .near
            }
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
