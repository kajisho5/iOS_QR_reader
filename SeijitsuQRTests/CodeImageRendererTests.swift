import Testing
import UIKit
@testable import SeijitsuQR

/// Codes are drawn again from their content (docs/DESIGN_1.1.md §1). Every drawing is read back with
/// Vision (the same reader as "写真から読み取る"), so a wrong encoding table fails here.
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

    @Test(arguments: samples.indices)
    func drawingReadsBackAsTheSameCode(_ index: Int) async throws {
        let (symbology, content) = Self.samples[index]
        #expect(CodeImageRenderer.canRender(symbology, content: content))
        let image = try #require(CodeImageRenderer.image(for: content, symbology: symbology, targetWidth: 1200))
        let codes = try await ImageCodeReader.detect(in: image)
        let read = try #require(codes.first { $0.symbology == symbology }, "\(symbology) not read back; got \(codes)")
        if symbology == .upce {
            // Readers may report UPC-E as is or expanded to its 12-digit UPC-A number.
            #expect(read.content == content || read.content == "012345000065")
        } else {
            #expect(read.content == content)
        }
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
