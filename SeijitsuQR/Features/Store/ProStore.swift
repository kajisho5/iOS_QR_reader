import Foundation
import Observation
import StoreKit
import SwiftUI

/// The parts of a StoreKit transaction that decide whether Pro is unlocked.
struct EntitlementSnapshot: Equatable, Sendable {
    let productID: String
    let isVerified: Bool
    let isRevoked: Bool
}

/// The single non-consumable "Pro" purchase (StoreKit 2). There are no subscriptions.
/// Pro status is never cached by the app: it always comes from verified transactions.
@MainActor
@Observable
final class ProStore {
    enum ProductState: Equatable {
        case loading
        case loaded
        case failed
    }

    enum Notice: Identifiable, Equatable {
        case pending
        case purchaseFailed
        case restored
        case nothingToRestore
        case restoreFailed

        var id: Self { self }
    }

    private(set) var isPro = false
    private(set) var product: Product?
    private(set) var productState: ProductState = .loading
    private(set) var isWorking = false
    /// Price text used instead of the App Store's in the App Store screenshot test, where the simulator reads the
    /// sandbox storefront of its own region rather than Japan's. Never set by the app itself.
    var screenshotDisplayPrice: String?

    /// The price as the App Store gives it (or the screenshot override).
    var displayPrice: String? { screenshotDisplayPrice ?? product?.displayPrice }

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            // Purchases approved later (Ask to Buy), refunds and purchases on other devices arrive here.
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self.refreshEntitlements()
            }
        }
    }

    func start() async {
        await refreshEntitlements()
        await loadProduct()
    }

    func loadProduct() async {
        productState = .loading
        do {
            product = try await Product.products(for: [AppConstants.proProductID]).first
            productState = product == nil ? .failed : .loaded
        } catch {
            productState = .failed
        }
    }

    func refreshEntitlements() async {
        var snapshots: [EntitlementSnapshot] = []
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                snapshots.append(EntitlementSnapshot(productID: transaction.productID, isVerified: true, isRevoked: transaction.revocationDate != nil))
            case .unverified(let transaction, _):
                snapshots.append(EntitlementSnapshot(productID: transaction.productID, isVerified: false, isRevoked: transaction.revocationDate != nil))
            }
        }
        isPro = Self.hasPro(snapshots)
    }

    /// Pro is unlocked only by a verified, non-revoked transaction for the Pro product.
    nonisolated static func hasPro(_ entitlements: [EntitlementSnapshot], productID: String = AppConstants.proProductID) -> Bool {
        entitlements.contains { $0.productID == productID && $0.isVerified && !$0.isRevoked }
    }

    /// Uses SwiftUI's purchase action so the system presents the payment sheet in the right scene.
    /// Returns a notice to show, if any (nil after a successful purchase or a cancel).
    func purchase(with action: PurchaseAction) async -> Notice? {
        guard let product, !isWorking else { return nil }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await action(product) {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
                return nil
            case .success(.unverified):
                return .purchaseFailed
            case .pending:
                return .pending
            case .userCancelled:
                return nil
            @unknown default:
                return nil
            }
        } catch {
            return .purchaseFailed
        }
    }

    func restore() async -> Notice? {
        guard !isWorking else { return nil }
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return isPro ? .restored : .nothingToRestore
        } catch {
            return .restoreFailed
        }
    }
}
