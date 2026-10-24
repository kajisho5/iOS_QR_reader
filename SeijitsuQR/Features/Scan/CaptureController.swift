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

    @ObservationIgnored let engine = CaptureEngine()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var onDetect: ((DetectedCode) -> Void)?
    /// Incremented by every stop(). A start that was overtaken by a stop (e.g. the user left the
    /// scan tab while the camera was still starting) must not report `.running` afterwards:
    /// the session is stopped by then, and a stale `.running` would make the next start a no-op.
    @ObservationIgnored private var generation = 0

    var session: AVCaptureSession { engine.session }

    func start(onDetect: @escaping (DetectedCode) -> Void) async {
        self.onDetect = onDetect
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
            Task { @MainActor in self?.onDetect?(code) }
        }
        // stop() ran while the session was starting; its stopRunning is queued after this start.
        guard startGeneration == generation else { return }
        switch result {
        case .running(let reference):
            device = reference.device
            hasTorch = reference.device.hasTorch
            state = .running
        case .noCamera, .failed:
            state = .unavailable
        }
    }

    func stop() {
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

    func toggleTorch() async {
        isTorchOn = await engine.setTorch(!isTorchOn)
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
