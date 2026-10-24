import Photos
import UIKit

/// Saves an image with add-only access (the app never reads the photo library).
enum PhotoLibrarySaver {
    enum Outcome: Sendable {
        case saved
        case denied
        case failed
    }

    static func save(_ image: UIImage) async -> Outcome {
        guard let data = image.pngData() else { return .failed }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .denied }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
