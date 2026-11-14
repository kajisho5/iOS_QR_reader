import Foundation
import SwiftData
import Testing
import UIKit
@testable import SeijitsuQR

/// Codes sent to Apple Watch (docs/DESIGN_1.2.md §8, K): drawn on the iPhone, at most `WatchCodes.limit`.
@MainActor
struct WatchCodesTests {
    @Test func aFavoriteBecomesADrawnCode() throws {
        let container = try HistoryContainer.make(inMemory: true)
        let record = try HistoryRecorder(context: container.mainContext).record(
            RecordDraft(content: "WIFI:T:WPA;S:Guest;P:secret;;", kind: .wifi, symbology: .qr, source: .camera), isPro: true)
        let code = try #require(WatchLink.code(record))
        #expect(code.title == "Guest")
        #expect(UIImage(data: code.image) != nil)
    }

    @Test func theListIsCappedAndRoundTrips() throws {
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        let codes = (0..<15).map { WatchCode(id: UUID(), title: "\($0)", kindTitle: "URL", image: png) }
        let decoded = WatchCodes.decode(try WatchCodes.encode(codes))
        #expect(decoded.count == WatchCodes.limit)
        #expect(decoded.first == codes.first)
    }
}
