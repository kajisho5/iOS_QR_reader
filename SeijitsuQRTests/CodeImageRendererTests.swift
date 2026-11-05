import Testing
import UIKit
@testable import SeijitsuQR

/// Codes are drawn again only for symbologies CoreImage can generate (docs/DESIGN_1.1.md §1).
@MainActor
struct CodeImageRendererTests {
    @Test(arguments: [CodeSymbology.qr, .code128, .pdf417, .aztec])
    func supportedSymbologiesRender(_ symbology: CodeSymbology) throws {
        let image = try #require(CodeImageRenderer.image(for: "SEIJITSU-12345", symbology: symbology, targetWidth: 600))
        #expect(image.size.width > 0 && image.size.height > 0)
    }

    @Test(arguments: [CodeSymbology.ean13, .ean8, .upce, .code39, .code93, .itf14, .dataMatrix])
    func unsupportedSymbologiesSaySo(_ symbology: CodeSymbology) {
        #expect(!CodeImageRenderer.canRender(symbology, content: "4901234567894"))
        #expect(CodeImageRenderer.image(for: "4901234567894", symbology: symbology) == nil)
    }

    @Test func code128NeedsASCII() {
        #expect(!CodeImageRenderer.canRender(.code128, content: "誠実"))
        #expect(CodeImageRenderer.canRender(.qr, content: "誠実"))
    }
}
