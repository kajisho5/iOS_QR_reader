import Foundation
import StoreKitTest
import Testing
@testable import SeijitsuQR

/// Runs against the local StoreKit configuration (no App Store connection).
@MainActor
@Suite(.serialized)
struct ProStoreTests {
    private let session: SKTestSession

    init() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "Configuration", withExtension: "storekit"))
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    @Test func loadsTheSingleNonConsumableProduct() async throws {
        let store = ProStore()
        await store.loadProduct()
        let product = try #require(store.product)
        #expect(product.id == AppConstants.proProductID)
        #expect(product.type == .nonConsumable)
        #expect(store.productState == .loaded)
    }

    @Test func purchaseUnlocksPro() async throws {
        let store = ProStore()
        await store.refreshEntitlements()
        #expect(store.isPro == false)
        try await session.buyProduct(identifier: AppConstants.proProductID)
        await store.refreshEntitlements()
        #expect(store.isPro == true)
    }

    @Test func refundRemovesPro() async throws {
        let store = ProStore()
        try await session.buyProduct(identifier: AppConstants.proProductID)
        await store.refreshEntitlements()
        #expect(store.isPro == true)
        for transaction in session.allTransactions() {
            try session.refundTransaction(identifier: transaction.identifier)
        }
        await store.refreshEntitlements()
        #expect(store.isPro == false)
    }
}

private final class BundleToken {}
