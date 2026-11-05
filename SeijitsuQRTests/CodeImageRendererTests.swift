import Testing
import UIKit
@testable import SeijitsuQR

/// Codes are drawn again from their content (docs/DESIGN_1.1.md §1).
/// Vision cannot be used here (its barcode model does not load in the CI simulator), so the hand-written
/// encodings are pinned to bar patterns that an independent decoder (zxing-cpp) read back as the same content.
@MainActor
struct CodeImageRendererTests {
    nonisolated static let samples: [(CodeSymbology, String)] = [
        (.qr, "https://www.example.co.jp/誠実"),
        (.code128, "SEIJITSU-12345"),
        (.pdf417, "SEIJITSU-12345"),
        (.aztec, "SEIJITSU-12345"),
        (.ean13, "4901234567894"),
        (.ean8, "49123456"),
        (.upce, "01234565"),
        (.code39, "SEIJITSU-123"),
        (.code93, "SEIJITSU-123"),
        (.itf14, "14901234567891"),
    ]

    /// Bar patterns ("1" = bar module) checked with zxing-cpp: each decodes to its content
    /// (UPC-E to its expanded number 0012345000065).
    nonisolated static let golden: [(CodeSymbology, String, String)] = [
        (.ean13, "4901234567894", "10100010110100111001100100100110100001001110101010100111010100001000100100100011101001011100101"),
        (.ean8, "49123456", "1010100011000101100110010010011010101000010101110010011101010000101"),
        (.upce, "01234565", "101011001100100110111101001110101110010101111010101"),
        (.code39, "SEIJITSU-123", "1000101110111010101110101110001011101011100010101011101000111010101011100011101010111010001110101010111011100010101110101110001011100010101011101000101011101110111010001010111010111000101011101110111000101010100010111011101"),
        (.code93, "SEIJITSU-123", "1010111101101011001100100101011000101001101001011000101101001101101011001100101101001011101010010001010001001010000101100010101010110001010111101"),
        (.itf14, "14901234567891", "101011101010001011100010111010001110001011101000101011100011101110100010100011101000111000101010001010111000111010001110101110100011101"),
    ]

    @Test(arguments: samples.indices)
    func supportedSymbologiesDraw(_ index: Int) throws {
        let (symbology, content) = Self.samples[index]
        #expect(CodeImageRenderer.canRender(symbology, content: content))
        let image = try #require(CodeImageRenderer.image(for: content, symbology: symbology, targetWidth: 1200))
        #expect(image.size.width >= 600 && image.size.height > 0)
    }

    @Test(arguments: golden.indices)
    func linearEncodingMatchesVerifiedPattern(_ index: Int) throws {
        let (symbology, content, expected) = Self.golden[index]
        let modules = try #require(LinearBarcodeEncoder.modules(for: content, symbology: symbology))
        #expect(modules.map { $0 ? "1" : "0" }.joined() == expected)
    }

    @Test func dataMatrixIsNotDrawn() {
        #expect(!CodeImageRenderer.canRender(.dataMatrix, content: "SEIJITSU"))
        #expect(CodeImageRenderer.image(for: "SEIJITSU", symbology: .dataMatrix) == nil)
    }

    @Test func contentThatBreaksTheStandardIsNotDrawn() {
        #expect(!CodeImageRenderer.canRender(.ean13, content: "4901234567890"))  // wrong check digit
        #expect(!CodeImageRenderer.canRender(.ean13, content: "490123456789"))  // 12 digits
        #expect(!CodeImageRenderer.canRender(.itf14, content: "14901234567890"))
        #expect(!CodeImageRenderer.canRender(.code39, content: "lowercase"))
        #expect(!CodeImageRenderer.canRender(.code128, content: "誠実"))
        #expect(CodeImageRenderer.canRender(.qr, content: "誠実"))
    }

    @Test func gs1CheckDigit() {
        #expect(LinearBarcodeEncoder.gs1CheckDigit([4, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) == 4)
        #expect(LinearBarcodeEncoder.expandUPCE([0, 1, 2, 3, 4, 5, 6]) == [0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 6])
    }

    @Test func ean13Layout() throws {
        // 3 guard + 6×7 + 5 centre + 6×7 + 3 guard modules.
        let modules = try #require(LinearBarcodeEncoder.ean13("4901234567894"))
        #expect(modules.count == 95)
        #expect(Array(modules.prefix(3)) == [true, false, true])
    }
}
