import CoreLocation

/// One-shot current location for the "地図の位置" form (docs/DESIGN_1.2.md §1, L). Asks for when-in-use access
/// only when the user taps "現在地を入れる"; the coordinate goes into the form and nowhere else.
@MainActor
final class CurrentLocation: NSObject, @preconcurrency CLLocationManagerDelegate {
    enum Failure: Error, Equatable {
        /// Location access is off for the app (or for the device).
        case denied
        /// No fix could be obtained.
        case unavailable
    }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, any Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request() async throws -> CLLocationCoordinate2D {
        finish(.failure(Failure.unavailable))  // a second tap replaces the first request
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined: manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
            default: finish(.failure(Failure.denied))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: finish(.failure(Failure.denied))
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last { finish(.success(location.coordinate)) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        finish(.failure(Failure.unavailable))
    }

    private func finish(_ result: Result<CLLocationCoordinate2D, any Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
