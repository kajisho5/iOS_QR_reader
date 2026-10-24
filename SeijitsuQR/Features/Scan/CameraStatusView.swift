import SwiftUI
import UIKit

/// Shown instead of the camera when it cannot be used, always with an alternative path.
struct CameraStatusView: View {
    enum Reason {
        case denied
        case restricted
        case unavailable
        case multitasking
    }

    let reason: Reason
    let onPickPhoto: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "camera.slash")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 104, height: 104)
                    .background(Circle().fill(AppColor.accentSoft))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if reason == .denied {
                    Text(L10n.scanPrivacyFootnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: 12) {
                    if reason == .denied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            Text(L10n.commonOpenSettings)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    Button(action: onPickPhoto) {
                        Label(L10n.scanPhoto, systemImage: "photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 48)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(.systemGroupedBackground))
    }

    private var title: String {
        switch reason {
        case .denied: L10n.scanDeniedTitle
        case .restricted: L10n.scanRestrictedTitle
        case .unavailable: L10n.scanUnavailableTitle
        case .multitasking: L10n.scanMultitaskingTitle
        }
    }

    private var message: String {
        switch reason {
        case .denied: L10n.scanDeniedMessage
        case .restricted: L10n.scanRestrictedMessage
        case .unavailable: L10n.scanUnavailableMessage
        case .multitasking: L10n.scanMultitaskingMessage
        }
    }
}
