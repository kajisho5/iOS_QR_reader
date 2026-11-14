import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Colors for a created QR code (docs/DESIGN_1.2.md §7, O). Only combinations that scanners read reliably can be
/// chosen: the modules darker than the background, with a contrast ratio of at least 4.5:1 (WCAG formula).
struct QRColor: Equatable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    /// Relative luminance (WCAG 2.x).
    var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: 1) }
    var ciColor: CIColor { CIColor(red: red, green: green, blue: blue) }

    static let black = QRColor(hex: 0x000000)
    static let white = QRColor(hex: 0xFFFFFF)
}

enum QRColorPalette {
    static let foregrounds: [QRColor] = [0x000000, 0x0A5F4E, 0x1E3A8A, 0x5B21B6, 0x7C2D12, 0x9D174D, 0x374151, 0x991B1B].map(QRColor.init(hex:))
    static let backgrounds: [QRColor] = [0xFFFFFF, 0xFFF8E7, 0xEAF7F2, 0xEEF2FF, 0xFDF2F8, 0xF3F4F6].map(QRColor.init(hex:))
    static let minimumContrast = 4.5

    static func contrast(_ a: QRColor, _ b: QRColor) -> Double {
        let (light, dark) = a.luminance >= b.luminance ? (a, b) : (b, a)
        return (light.luminance + 0.05) / (dark.luminance + 0.05)
    }

    /// The modules must be darker than the background (inverted codes fail on some scanners) and differ enough.
    static func isReadable(foreground: QRColor, background: QRColor) -> Bool {
        foreground.luminance < background.luminance && contrast(foreground, background) >= minimumContrast
    }

    /// The black-on-white code with black replaced by `foreground` and white by `background`.
    static func colored(_ image: UIImage, foreground: QRColor, background: QRColor) -> UIImage? {
        if foreground == .black && background == .white { return image }
        guard let cgImage = image.cgImage else { return nil }
        let filter = CIFilter.falseColor()
        filter.inputImage = CIImage(cgImage: cgImage)
        filter.color0 = foreground.ciColor
        filter.color1 = background.ciColor
        guard let output = filter.outputImage,
              let colored = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: colored, scale: image.scale, orientation: image.imageOrientation)
    }
}
