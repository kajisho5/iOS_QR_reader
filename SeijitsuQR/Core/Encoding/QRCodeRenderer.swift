import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Renders QR codes on device with CoreImage: black modules on white with a 4-module quiet zone,
/// in both light and dark mode, so the code stays scannable.
enum QRCodeRenderer {
    /// Returns nil when the content does not fit in a QR code.
    @MainActor
    static func image(for content: String, targetSide: CGFloat = 1024) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage, output.extent.width > 0 else { return nil }

        let quietZone: CGFloat = 4
        let modules = output.extent.width + quietZone * 2
        let scale = max(1, (targetSide / modules).rounded(.down))
        let scaled = output.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }

        let side = modules * scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            context.cgContext.interpolationQuality = .none
            // UIKit's coordinate system is flipped relative to Core Graphics.
            context.cgContext.translateBy(x: 0, y: side)
            context.cgContext.scaleBy(x: 1, y: -1)
            let inset = quietZone * scale
            context.cgContext.draw(cgImage, in: CGRect(x: inset, y: inset, width: scaled.extent.width, height: scaled.extent.height))
        }
    }
}
