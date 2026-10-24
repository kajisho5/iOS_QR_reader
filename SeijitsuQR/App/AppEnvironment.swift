import SwiftUI

extension EnvironmentValues {
    /// Whether the one-time Pro purchase is active. Set from StoreKit in the purchase step;
    /// until then the free plan applies everywhere.
    @Entry var isProUnlocked: Bool = false
}
