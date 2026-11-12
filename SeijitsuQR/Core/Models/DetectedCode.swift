/// A code read by the camera or from an image.
struct DetectedCode: Equatable, Hashable, Sendable {
    let content: String
    let symbology: CodeSymbology

    var dedupeKey: String { "\(symbology.rawValue)|\(content)" }
}
