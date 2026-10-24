import Testing
@testable import SeijitsuQR

/// The purchase flow itself is exercised manually with StoreKit/Configuration.storekit (see README):
/// StoreKitTest sessions are not honored by the CI simulator, so these tests cover the app's own rule.
struct ProStoreTests {
    private let pro = AppConstants.proProductID

    @Test func verifiedProTransactionUnlocks() {
        #expect(ProStore.hasPro([EntitlementSnapshot(productID: pro, isVerified: true, isRevoked: false)]))
    }

    @Test func nothingPurchasedStaysFree() {
        #expect(!ProStore.hasPro([]))
    }

    @Test func unverifiedTransactionDoesNotUnlock() {
        #expect(!ProStore.hasPro([EntitlementSnapshot(productID: pro, isVerified: false, isRevoked: false)]))
    }

    @Test func refundedTransactionDoesNotUnlock() {
        #expect(!ProStore.hasPro([EntitlementSnapshot(productID: pro, isVerified: true, isRevoked: true)]))
    }

    @Test func otherProductsDoNotUnlock() {
        #expect(!ProStore.hasPro([EntitlementSnapshot(productID: "com.example.other", isVerified: true, isRevoked: false)]))
    }
}
