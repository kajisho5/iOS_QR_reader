import SwiftUI

extension PayloadKind {
    var title: String {
        switch self {
        case .url: L10n.kindUrl
        case .wifi: L10n.kindWifi
        case .contact: L10n.kindContact
        case .email: L10n.kindEmail
        case .phone: L10n.kindPhone
        case .sms: L10n.kindSms
        case .geo: L10n.kindGeo
        case .event: L10n.kindEvent
        case .text: L10n.kindText
        }
    }

    var systemImage: String {
        switch self {
        case .url: "link"
        case .wifi: "wifi"
        case .contact: "person.crop.circle"
        case .email: "envelope"
        case .phone: "phone"
        case .sms: "message"
        case .geo: "mappin.and.ellipse"
        case .event: "calendar"
        case .text: "doc.text"
        }
    }
}

extension CodeSymbology {
    var title: String {
        switch self {
        case .qr: L10n.symbologyQr
        case .ean13: L10n.symbologyEan13
        case .ean8: L10n.symbologyEan8
        case .upce: L10n.symbologyUpce
        case .code39: L10n.symbologyCode39
        case .code93: L10n.symbologyCode93
        case .code128: L10n.symbologyCode128
        case .itf14: L10n.symbologyItf14
        case .pdf417: L10n.symbologyPdf417
        case .aztec: L10n.symbologyAztec
        case .dataMatrix: L10n.symbologyDataMatrix
        }
    }

    var isLinear: Bool {
        switch self {
        case .ean13, .ean8, .upce, .code39, .code93, .code128, .itf14: true
        case .qr, .pdf417, .aztec, .dataMatrix: false
        }
    }
}

/// Rounded tile with the kind's symbol. Decorative: the kind is always also given as text.
struct KindTile: View {
    let kind: PayloadKind
    var symbology: CodeSymbology?
    var size: CGFloat = 44

    var body: some View {
        let symbol = (kind == .text && symbology?.isLinear == true) ? "barcode" : kind.systemImage
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(AppColor.kind(kind))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}
