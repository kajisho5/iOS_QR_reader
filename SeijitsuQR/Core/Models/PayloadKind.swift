import Foundation

/// The kind of content a code holds. Stored in history as `rawValue`, so cases must not be renamed.
enum PayloadKind: String, CaseIterable, Codable, Sendable {
    case url
    case wifi
    case contact
    case email
    case phone
    case sms
    case geo
    case event
    case text
}

/// Barcode symbologies the scanner recognizes. Stored in history as `rawValue`.
enum CodeSymbology: String, CaseIterable, Codable, Sendable {
    case qr
    case ean13
    case ean8
    case upce
    case code39
    case code93
    case code128
    case itf14
    case pdf417
    case aztec
    case dataMatrix
}

/// Where a history record came from. Stored in history as `rawValue`.
enum RecordSource: String, Codable, Sendable {
    case camera
    case photo
    case created
}
