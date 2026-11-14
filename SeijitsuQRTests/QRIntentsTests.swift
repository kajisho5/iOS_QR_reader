import Testing
import UIKit
@testable import SeijitsuQR

/// Shortcuts actions (docs/DESIGN_1.2.md §6, N).
@MainActor
struct QRIntentsTests {
    @Test func createMakesAPNGOfTheText() throws {
        let data = try CreateQRCodeIntent.png(for: "https://example.com")
        #expect(UIImage(data: data) != nil)
    }

    @Test func createRejectsEmptyText() {
        #expect(throws: QRIntentError.self) {
            _ = try CreateQRCodeIntent.png(for: "  ")
        }
    }
}
