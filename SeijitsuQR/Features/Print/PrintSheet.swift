import UIKit

/// Lays out and draws a code for printing (docs/DESIGN_1.2.md §4, J): one large code, or the same code repeated
/// like labels (3 × 6 on A4). Printed through iOS (AirPrint); the app itself sends nothing anywhere.
enum PrintSheet {
    enum Layout: String, CaseIterable, Hashable, Sendable {
        case single
        case labels
    }

    struct Options: Equatable, Sendable {
        var layout: Layout = .single
        /// Side of the code in centimetres (single layout).
        var sizeCentimeters = 6
        var showsCaption = true

        static let sizeRange = 3...15
    }

    /// One code on the page: the square for the code and the line under it for the caption.
    struct Cell: Equatable {
        var code: CGRect
        var caption: CGRect?
    }

    /// A4 in points (1/72 inch).
    static let page = CGSize(width: 595.28, height: 841.89)
    static let pointsPerCentimeter: CGFloat = 72 / 2.54
    static let margin: CGFloat = 28
    static let labelColumns = 3
    static let labelRows = 6

    static func cells(for options: Options) -> [Cell] {
        switch options.layout {
        case .single:
            let side = min(CGFloat(options.sizeCentimeters) * pointsPerCentimeter, page.width - 2 * margin)
            let code = CGRect(x: (page.width - side) / 2, y: 72, width: side, height: side)
            let caption = options.showsCaption ? CGRect(x: margin, y: code.maxY + 12, width: page.width - 2 * margin, height: 22) : nil
            return [Cell(code: code, caption: caption)]
        case .labels:
            let cellWidth = (page.width - 2 * margin) / CGFloat(labelColumns)
            let cellHeight = (page.height - 2 * margin) / CGFloat(labelRows)
            let captionHeight: CGFloat = options.showsCaption ? 14 : 0
            let side = min(cellWidth, cellHeight - captionHeight) - 16
            var cells: [Cell] = []
            for row in 0..<labelRows {
                for column in 0..<labelColumns {
                    let x = margin + CGFloat(column) * cellWidth
                    let y = margin + CGFloat(row) * cellHeight
                    let top = y + (cellHeight - side - captionHeight) / 2
                    let code = CGRect(x: x + (cellWidth - side) / 2, y: top, width: side, height: side)
                    let caption = options.showsCaption ? CGRect(x: x + 4, y: code.maxY + 2, width: cellWidth - 8, height: captionHeight) : nil
                    cells.append(Cell(code: code, caption: caption))
                }
            }
            return cells
        }
    }

    /// The page as PDF (A4), for the print controller.
    static func pdf(image: UIImage, caption: String, options: Options) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: page))
        return renderer.pdfData { context in
            context.beginPage()
            draw(image: image, caption: caption, options: options, in: context.cgContext)
        }
    }

    /// A small picture of the page for the settings screen.
    static func preview(image: UIImage, caption: String, options: Options, width: CGFloat) -> UIImage {
        let scale = width / page.width
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: page.height * scale), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: context.format.bounds.size))
            context.cgContext.scaleBy(x: scale, y: scale)
            draw(image: image, caption: caption, options: options, in: context.cgContext)
        }
    }

    private static func draw(image: UIImage, caption: String, options: Options, in context: CGContext) {
        context.interpolationQuality = .none  // keep the modules sharp
        let fontSize: CGFloat = options.layout == .single ? 14 : 7
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingMiddle
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph,
        ]
        for cell in cells(for: options) {
            image.draw(in: aspectFit(image.size, in: cell.code))
            if let rect = cell.caption, !caption.isEmpty {
                (caption as NSString).draw(in: rect, withAttributes: attributes)
            }
        }
    }

    /// Barcodes are wider than tall: fit them in the square without stretching.
    static func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: rect.midX - fitted.width / 2, y: rect.midY - fitted.height / 2, width: fitted.width, height: fitted.height)
    }
}
