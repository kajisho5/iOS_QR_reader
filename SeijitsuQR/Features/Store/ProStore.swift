import Foundation
import Observation
import StoreKit
import SwiftUI

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
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == AppConstants.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isPro = unlocked
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
