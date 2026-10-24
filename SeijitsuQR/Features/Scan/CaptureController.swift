@preconcurrency import AVFoundation
import Observation

/// Camera state for the scan screen: authorization, running, interruptions, torch.
@MainActor
@Observable
final class CaptureController {
    enum State: Equatable {
        case idle
        case starting
        case running
        case denied
        case restricted
        case unavailable
        /// iPad: the system stops the camera while other apps share the screen.
        case interruptedByMultitasking
    }

    private(set) var state: State = .idle
    private(set) var isTorchOn = false
    private(set) var hasTorch = false
    private(set) var device: AVCaptureDevice?
    /// Zoom in device units; `displayZoom` is what people see (1× = the wide lens).
    private(set) var zoomFactor: CGFloat = 1
    private(set) var zoomRange: ClosedRange<CGFloat> = 1...1
    @ObservationIgnored private var zoomDisplayMultiplier: CGFloat = 1

    var displayZoom: CGFloat { zoomFactor * zoomDisplayMultiplier }
    var standardZoomFactor: CGFloat { 1 / zoomDisplayMultiplier }

    @ObservationIgnored let engine = CaptureEngine.shared
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var onDetect: ((DetectedCode) -> Void)?
    /// Incremented by every stop(). A start that was overtaken by a stop (e.g. the user left the
    /// scan tab while the camera was still starting) must not report `.running` afterwards:
    /// the session is stopped by then, and a stale `.running` would make the next start a no-op.
    @ObservationIgnored private var generation = 0
    /// Codes are passed on only while this is true; it turns off as soon as the scan screen is left,
    /// even while the camera is still kept running for a moment (see `stop(after:)`).
    @ObservationIgnored private var isDetecting = false
    @ObservationIgnored private var pendingStop: Task<Void, Never>?

    var session: AVCaptureSession { engine.session }

    func start(onDetect: @escaping (DetectedCode) -> Void) async {
        self.onDetect = onDetect
        // Coming back within the grace period of stop(after:): the session is still running.
        pendingStop?.cancel()
        pendingStop = nil
        isDetecting = true
        guard state != .running, state != .starting else { return }
        let startGeneration = generation

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard startGeneration == generation else { return }
            guard granted else {
                state = .denied
                return
            }
        case .restricted:
            state = .restricted
            return
        case .denied:
            state = .denied
            return
        @unknown default:
            state = .denied
            return
        }

        state = .starting
        observeInterruptions()
        let result = await engine.start { [weak self] code in
            Task { @MainActor in
                guard let self, self.isDetecting else { return }
                self.onDetect?(code)
            }
        }
        // stop() ran while the session was starting; its stopRunning is queued after this start.
        guard startGeneration == generation else { return }
        switch result {
        case .running(let reference):
            let camera = reference.device
            device = camera
            hasTorch = camera.hasTorch
            zoomDisplayMultiplier = CameraZoom.displayMultiplier(for: camera)
            zoomRange = camera.minAvailableVideoZoomFactor...max(camera.minAvailableVideoZoomFactor, CameraZoom.maximumFactor(for: camera))
            zoomFactor = camera.videoZoomFactor
            observeSubjectArea(of: camera)
            state = .running
        case .noCamera, .failed:
            state = .unavailable
        }
    }

    /// Leaving the scan screen: stops reading codes and turns the torch off at once, but keeps the
    /// session running for `delay`, so switching tabs back and forth does not restart the camera
    /// (starting a capture session takes a noticeable moment, longer with multi-camera devices).
    func stop(after delay: Duration) {
        isDetecting = false
        if isTorchOn { Task { await setTorch(false) } }
        pendingStop?.cancel()
        pendingStop = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    func stop() {
        pendingStop?.cancel()
        pendingStop = nil
        isDetecting = false
        generation += 1
        engine.stop()
        isTorchOn = false
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        if state == .running || state == .starting || state == .interruptedByMultitasking {
            state = .idle
        }
    }

    func setZoom(_ factor: CGFloat) {
        guard state == .running else { return }
        let clamped = min(max(factor, zoomRange.lowerBound), zoomRange.upperBound)
        zoomFactor = clamped
        engine.setZoom(clamped)
    }

    /// One zoom step for VoiceOver (adjustable) and similar controls: ×1.5 or ÷1.5.
    func stepZoom(in zoomIn: Bool) {
        setZoom(zoomIn ? zoomFactor * 1.5 : zoomFactor / 1.5)
    }

    func resetZoom() {
        setZoom(standardZoomFactor)
    }

    func focus(atDevicePoint point: CGPoint) {
        guard state == .running else { return }
        engine.focus(at: point)
    }

    func toggleTorch() async {
        await setTorch(!isTorchOn)
    }

    private func setTorch(_ isOn: Bool) async {
        isTorchOn = await engine.setTorch(isOn)
    }

    private func observeSubjectArea(of camera: AVCaptureDevice) {
        observers.append(NotificationCenter.default.addObserver(forName: AVCaptureDevice.subjectAreaDidChangeNotification, object: camera, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.engine.resumeContinuousFocus()
            }
        })
    }

    private func observeInterruptions() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: engine.session, queue: .main) { [weak self] note in
            let reason = (note.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int).flatMap(AVCaptureSession.InterruptionReason.init(rawValue:))
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isTorchOn = false
                if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                    self.state = .interruptedByMultitasking
                }
            }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: engine.session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .interruptedByMultitasking else { return }
                self.state = .running
            }
        })
    }
}
