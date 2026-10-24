import Foundation
@preconcurrency import NetworkExtension

/// Joins a Wi-Fi network through the system (requires the Hotspot Configuration entitlement).
/// iOS shows its own confirmation dialog; the app never sees whether the user is online.
enum WiFiConnector {
    enum Outcome: Sendable {
        case connected
        case cancelled
        case failed
    }

    @MainActor
    static func connect(_ network: WiFiNetwork) async -> Outcome {
        let configuration: NEHotspotConfiguration
        switch network.security {
        case .open:
            configuration = NEHotspotConfiguration(ssid: network.ssid)
        case .wep:
            configuration = NEHotspotConfiguration(ssid: network.ssid, passphrase: network.password ?? "", isWEP: true)
        case .wpa:
            configuration = NEHotspotConfiguration(ssid: network.ssid, passphrase: network.password ?? "", isWEP: false)
        }
        configuration.hidden = network.isHidden
        configuration.joinOnce = false

        do {
            try await NEHotspotConfigurationManager.shared.apply(configuration)
            return .connected
        } catch let error as NSError where error.domain == NEHotspotConfigurationErrorDomain {
            switch NEHotspotConfigurationError(rawValue: error.code) {
            case .alreadyAssociated: return .connected
            case .userDenied: return .cancelled
            default: return .failed
            }
        } catch {
            return .failed
        }
    }
}
