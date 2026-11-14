import Testing
import UIKit
@testable import SeijitsuQR

/// QR colors (docs/DESIGN_1.2.md §7, O): only combinations scanners read reliably.
@MainActor
struct QRColorPaletteTests {
    @Test func blackOnWhiteIsTheMaximumContrast() {
        #expect(abs(QRColorPalette.contrast(.black, .white) - 21) < 0.01)
        #expect(QRColorPalette.isReadable(foreground: .black, background: .white))
    }

    @Test func invertedOrFaintCombinationsAreRefused() {
        #expect(!QRColorPalette.isReadable(foreground: .white, background: .black))  // inverted
        #expect(!QRColorPalette.isReadable(foreground: QRColor(hex: 0xF59E0B), background: .white))  // amber on white: too faint
        #expect(!QRColorPalette.isReadable(foreground: .black, background: QRColor(hex: 0x111827)))  // dark on dark
    }

    @Test func everyColorHasAtLeastOneReadablePartner() {
        for fg in QRColorPalette.foregrounds {
            #expect(QRColorPalette.backgrounds.contains { QRColorPalette.isReadable(foreground: fg, background: $0) })
        }
        for bg in QRColorPalette.backgrounds {
            #expect(QRColorPalette.foregrounds.contains { QRColorPalette.isReadable(foreground: $0, background: bg) })
        }
    }

    @Test func coloringKeepsTheSize() throws {
        let image = try #require(QRCodeRenderer.image(for: "https://example.com", targetSide: 300))
        let colored = try #require(QRColorPalette.colored(image, foreground: QRColor(hex: 0x0A5F4E), background: QRColor(hex: 0xFFF8E7)))
        #expect(colored.size == image.size)
    }
}
