import StoreKit
import SwiftUI

/// The purchase screen. Shown only when the user taps a locked feature or "購入" in Settings.
/// It states plainly that this is a one-time payment and shows the price exactly as the App Store gives it.
struct PaywallView: View {
    @Environment(ProStore.self) private var store
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var notice: ProStore.Notice?

    /// The purchase and restore buttons stay at the bottom, within thumb reach. At accessibility
    /// text sizes they follow the content instead, so they do not cover most of the screen.
    private var pinsPurchase: Bool { !dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    honesty
                    features
                    Text(L10n.paywallScanFree)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if !pinsPurchase {
                        purchaseSection
                    }
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                if pinsPurchase {
                    VStack(spacing: 4) {
                        purchaseSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .background {
                        Color(.systemBackground).ignoresSafeArea()
                    }
                    .overlay(alignment: .top) { Divider() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label(L10n.commonClose, systemImage: "xmark")
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .alert(notice?.title ?? "", isPresented: isNoticePresented, presenting: notice) { _ in
                Button(L10n.commonClose, role: .cancel) {}
            } message: { notice in
                Text(notice.message)
            }
        }
        .task { if store.product == nil { await store.loadProduct() } }
    }

    private var header: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(AppColor.accentFill)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "qrcode")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
            Text(L10n.paywallTitle)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(L10n.paywallSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var honesty: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.paywallHonestOneTime, systemImage: "checkmark.circle.fill")
            Label(L10n.paywallHonestNoAds, systemImage: "checkmark.circle.fill")
        }
        .font(.body.weight(.bold))
        .foregroundStyle(AppColor.accentOnSoft)
        .symbolRenderingMode(.monochrome)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.accentSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 1.5)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.paywallFeaturesHeader)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
            FeatureRow(systemImage: "infinity", title: L10n.paywallFeatureHistoryTitle, detail: L10n.paywallFeatureHistoryDetail)
            FeatureRow(systemImage: "qrcode", title: L10n.paywallFeatureCreateTitle, detail: L10n.paywallFeatureCreateDetail)
            FeatureRow(systemImage: "tablecells", title: L10n.paywallFeatureCsvTitle, detail: L10n.paywallFeatureCsvDetail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if store.isPro {
            Label(L10n.paywallPurchased, systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(AppColor.accentOnSoft)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else if let product = store.product {
            Button {
                Task { notice = await store.purchase(with: purchase) }
            } label: {
                if store.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(L10n.paywallBuy(product.displayPrice))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.isWorking)
        } else if store.productState == .failed {
            VStack(spacing: 8) {
                Text(L10n.paywallLoadFailed)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(L10n.paywallRetry) { Task { await store.loadProduct() } }
            }
        } else {
            ProgressView()
                .frame(minHeight: 56)
        }
        Button(L10n.paywallRestore) {
            Task { notice = await store.restore() }
        }
        .font(.body.weight(.semibold))
        .frame(minHeight: 44)
        .disabled(store.isWorking)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text(L10n.paywallFooterCharge + "\n" + L10n.paywallFooterRestore)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link(L10n.paywallTerms, destination: AppConstants.termsOfUseURL)
                Link(L10n.paywallPrivacy, destination: AppConstants.privacyPolicyURL)
            }
            .font(.caption.weight(.semibold))
        }
    }

    private var isNoticePresented: Binding<Bool> {
        Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(AppColor.accentSoft))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension ProStore.Notice {
    var title: String {
        switch self {
        case .pending: L10n.paywallPendingTitle
        case .purchaseFailed: L10n.paywallFailedTitle
        case .restored: L10n.paywallRestoredTitle
        case .nothingToRestore: L10n.paywallNothingToRestoreTitle
        case .restoreFailed: L10n.paywallRestoreFailedTitle
        }
    }

    var message: String {
        switch self {
        case .pending: L10n.paywallPendingMessage
        case .purchaseFailed: L10n.paywallFailedMessage
        case .restored: L10n.paywallRestoredMessage
        case .nothingToRestore: L10n.paywallNothingToRestoreMessage
        case .restoreFailed: L10n.paywallRestoreFailedMessage
        }
    }
}
