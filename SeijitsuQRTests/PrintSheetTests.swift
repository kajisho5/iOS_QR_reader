import Testing
import UIKit
@testable import SeijitsuQR

/// Print layout (docs/DESIGN_1.2.md §4, J): sizes in centimetres and every label inside the page.
struct PrintSheetTests {
    private let page = CGRect(origin: .zero, size: PrintSheet.page)

    @Test func singleCodeHasTheChosenSize() throws {
        let cell = try #require(PrintSheet.cells(for: .init(layout: .single, sizeCentimeters: 6)).first)
        #expect(abs(cell.code.width - 6 * 72 / 2.54) < 0.01)
        #expect(cell.code.width == cell.code.height)
        #expect(page.contains(cell.code))
        #expect(try #require(cell.caption).minY > cell.code.maxY)
    }

    @Test func largestSingleCodeStillFitsTheWidth() throws {
        let cell = try #require(PrintSheet.cells(for: .init(layout: .single, sizeCentimeters: 15)).first)
        #expect(page.insetBy(dx: PrintSheet.margin - 0.01, dy: 0).contains(cell.code))
    }

    @Test(arguments: [true, false])
    func labelsAreEighteenNonOverlappingCellsInsideThePage(_ caption: Bool) {
        let cells = PrintSheet.cells(for: .init(layout: .labels, showsCaption: caption))
        #expect(cells.count == 18)
        for (i, cell) in cells.enumerated() {
            #expect(page.contains(cell.code))
            #expect((cell.caption != nil) == caption)
            for other in cells[(i + 1)...] {
                #expect(!cell.code.intersects(other.code))
            }
        }
    }

    @Test func barcodesKeepTheirShape() {
        let fitted = PrintSheet.aspectFit(CGSize(width: 300, height: 100), in: CGRect(x: 0, y: 0, width: 90, height: 90))
        #expect(fitted.width == 90)
        #expect(fitted.height == 30)
        #expect(fitted.midY == 45)
    }

    @Test func pdfIsOnePage() throws {
        let image = try #require(CodeImageRenderer.image(for: "https://example.com", symbology: .qr))
        let data = PrintSheet.pdf(image: image, caption: "example.com", options: .init(layout: .labels))
        let document = try #require(CGPDFDocument(CGDataProvider(data: data as CFData)!))
        #expect(document.numberOfPages == 1)
    }
}
