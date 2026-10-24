import ImageIO
import UIKit
@preconcurrency import Vision

extension CodeSymbology {
    init?(visionSymbology: VNBarcodeSymbology) {
        switch visionSymbology {
        case .qr: self = .qr
        case .ean13: self = .ean13
        case .ean8: self = .ean8
        case .upce: self = .upce
        case .code39: self = .code39
        case .code93: self = .code93
        case .code128: self = .code128
        case .itf14: self = .itf14
        case .pdf417: self = .pdf417
        case .aztec: self = .aztec
        case .dataMatrix: self = .dataMatrix
        default: return nil
        }
    }

    var visionSymbology: VNBarcodeSymbology {
        switch self {
        case .qr: .qr
        case .ean13: .ean13
        case .ean8: .ean8
        case .upce: .upce
        case .code39: .code39
        case .code93: .code93
        case .code128: .code128
        case .itf14: .itf14
        case .pdf417: .pdf417
        case .aztec: .aztec
        case .dataMatrix: .dataMatrix
        }
    }
}

/// Reads codes from a still image on device (Vision). Nothing leaves the device.
enum ImageCodeReader {
    private struct ImageInput: @unchecked Sendable {
        let image: CGImage
        let orientation: CGImagePropertyOrientation
    }

    static func detect(in image: UIImage) async throws -> [DetectedCode] {
        guard let cgImage = image.cgImage else { return [] }
        let input = ImageInput(image: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
        return try await Task.detached(priority: .userInitiated) {
            try detect(input)
        }.value
    }

    private static func detect(_ input: ImageInput) throws -> [DetectedCode] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = CodeSymbology.allCases.map(\.visionSymbology)
        let handler = VNImageRequestHandler(cgImage: input.image, orientation: input.orientation)
        try handler.perform([request])
        var seen = Set<String>()
        var codes: [DetectedCode] = []
        for observation in request.results ?? [] {
            guard let value = observation.payloadStringValue, !value.isEmpty,
                  let symbology = CodeSymbology(visionSymbology: observation.symbology)
            else { continue }
            let code = DetectedCode(content: value, symbology: symbology)
            if seen.insert(code.dedupeKey).inserted {
                codes.append(code)
            }
        }
        return codes
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
