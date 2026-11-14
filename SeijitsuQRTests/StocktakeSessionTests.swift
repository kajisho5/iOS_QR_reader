import Foundation
import Testing
@testable import SeijitsuQR

/// Counting while scanning (docs/DESIGN_1.2.md §5, I).
struct StocktakeSessionTests {
    private let jan = DetectedCode(content: "4901234567894", symbology: .ean13)
    private let shelf = DetectedCode(content: "SHELF-B-03", symbology: .qr)
    private let t0 = Date(timeIntervalSince1970: 1_793_000_000)

    @Test func holdingACodeCountsItOnce() {
        var session = StocktakeSession()
        #expect(session.observe(jan, at: t0) == 1)
        for i in 1...20 {  // detections every 0.1 s while in view
            #expect(session.observe(jan, at: t0.addingTimeInterval(Double(i) * 0.1)) == nil)
        }
        #expect(session.total == 1)
    }

    @Test func aCodeCountsAgainAfterLeavingTheViewForOneSecond() {
        var session = StocktakeSession()
        session.observe(jan, at: t0)
        #expect(session.observe(jan, at: t0.addingTimeInterval(0.9)) == nil)
        #expect(session.observe(jan, at: t0.addingTimeInterval(2.0)) == 2)
        #expect(session.observe(shelf, at: t0.addingTimeInterval(2.1)) == 1)
        #expect(session.total == 3)
        #expect(session.items.map(\.code) == [shelf, jan])
    }

    @Test func countsCanBeCorrected() {
        var session = StocktakeSession()
        session.observe(jan, at: t0)
        let id = jan.dedupeKey
        session.increment(id)
        session.increment(id)
        session.decrement(id)
        #expect(session.items.first?.count == 2)
        session.decrement(id)
        session.decrement(id)
        #expect(session.items.first?.count == 1)
        session.remove(id)
        #expect(session.isEmpty)
    }

    @Test func csvListsCodesOldestFirst() {
        var session = StocktakeSession()
        session.observe(jan, at: t0)
        session.observe(shelf, at: t0.addingTimeInterval(5))
        let csv = session.csv(headers: ["コード", "種類", "形式", "数", "最後に読んだ時刻"], kindTitle: { _ in "テキスト" },
                              symbologyTitle: { $0.rawValue }, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        let lines = csv.split(separator: "\r\n")
        #expect(lines[0] == "\u{FEFF}コード,種類,形式,数,最後に読んだ時刻")
        #expect(lines[1] == "4901234567894,テキスト,ean13,1,2026-10-26 16:33:20")
        #expect(lines[2].hasPrefix("SHELF-B-03,"))
    }
}
