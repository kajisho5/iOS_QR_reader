import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Draws a scanned code again from its content, for showing it on screen (docs/DESIGN_1.1.md §1).
/// Only the symbologies CoreImage can generate are supported; the drawing is black on white with a quiet zone.
/// The result reads the same as the original, but its pattern may differ (error correction, version, mask).
enum CodeImageRenderer {
    static func canRender(_ symbology: CodeSymbology, content: String) -> Bool {
        switch symbology {
        case .qr, .pdf417, .aztec: !content.isEmpty
        case .code128: !content.isEmpty && content.unicodeScalars.allSatisfy(\.isASCII)
        case .ean13, .ean8, .upce, .code39, .code93, .itf14, .dataMatrix: false
        }
    }

    /// Returns nil when the symbology cannot be generated or the content does not fit.
    @MainActor
    static func image(for content: String, symbology: CodeSymbology, targetWidth: CGFloat = 1024) -> UIImage? {
        guard canRender(symbology, content: content) else { return nil }
        let output: CIImage?
        let quietZone: CGFloat
        switch symbology {
        case .qr:
            return QRCodeRenderer.image(for: content, targetSide: targetWidth)
        case .code128:
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = Data(content.utf8)
            filter.quietSpace = 0
            filter.barcodeHeight = 48
            output = filter.outputImage
            quietZone = 10
        case .pdf417:
            let filter = CIFilter.pdf417BarcodeGenerator()
            filter.message = Data(content.utf8)
            output = filter.outputImage
            quietZone = 4
        case .aztec:
            let filter = CIFilter.aztecCodeGenerator()
            filter.message = Data(content.utf8)
            filter.correctionLevel = 23
            output = filter.outputImage
            quietZone = 2
        default:
            return nil
        }
        guard let output, output.extent.width > 0, output.extent.height > 0 else { return nil }

        let modulesWide = output.extent.width + quietZone * 2
        let scale = max(1, (targetWidth / modulesWide).rounded(.down))
        let scaled = output.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }

        let inset = quietZone * scale
        let size = CGSize(width: scaled.extent.width + inset * 2, height: scaled.extent.height + inset * 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.interpolationQuality = .none
            // UIKit's coordinate system is flipped relative to Core Graphics.
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            context.cgContext.draw(cgImage, in: CGRect(x: inset, y: inset, width: scaled.extent.width, height: scaled.extent.height))
        }
    }
}
