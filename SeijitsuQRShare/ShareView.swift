import ImageIO
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class ShareModel {
    enum State: Equatable {
        case reading
        case noCode
        case choosing([DetectedCode])
        case showing(DetectedCode)
    }

    var state: State = .reading
    var copied = false
    @ObservationIgnored let close: @MainActor () -> Void

    init(close: @escaping @MainActor () -> Void) {
        self.close = close
    }

    func read(_ data: Data?) async {
        guard let data, let image = Self.downscaled(data) else {
            state = .noCode
            return
        }
        let codes = (try? await ImageCodeReader.detect(in: image)) ?? []
        switch codes.count {
        case 0: state = .noCode
        case 1: show(codes[0])
        default: state = .choosing(codes)
        }
    }

    func show(_ code: DetectedCode) {
        state = .showing(code)
        try? PendingScans.append(PendingScan(content: code.content, symbologyRaw: code.symbology.rawValue, date: .now))
    }

    func copy(_ code: DetectedCode) {
        UIPasteboard.general.string = code.content
        copied = true
    }

    /// Large photos are read at most 3000 pixels on the long side, so the extension stays within its memory limit.
    private static func downscaled(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 3000,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

/// docs/design/18_entry_points.svg E2, without "open" (not possible from a share extension).
struct ShareView: View {
    let model: ShareModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                    Label(L10n.sharePrivacy, systemImage: "checkmark.shield")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.shareTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose) { model.close() }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .reading:
            HStack(spacing: 10) {
                ProgressView()
                Text(L10n.shareReading)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        case .noCode:
            ContentUnavailableView(L10n.scanNoCodeTitle, systemImage: "qrcode.viewfinder", description: Text(L10n.shareNoCodeMessage))
        case .choosing(let codes):
            Text(L10n.scanMultipleCodesMessage)
                .font(.headline)
            ForEach(codes, id: \.self) { code in
                Button { model.show(code) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.kindTitle(PayloadParser.parse(code.content).kind)).font(.footnote).foregroundStyle(.secondary)
                        Text(code.content).lineLimit(2).foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        case .showing(let code):
            result(code)
        }
    }

    @ViewBuilder
    private func result(_ code: DetectedCode) -> some View {
        let payload = PayloadParser.parse(code.content)
        Text(Self.kindTitle(payload.kind))
            .font(.title2.bold())
        Text(code.content)
            .font(.body.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        if case .url(let url) = payload {
            let risks = URLRiskAnalyzer.risks(in: code.content, url: url)
            if let host = url.host {
                LabeledContent(L10n.shareDomain, value: host)
            }
            ForEach(risks, id: \.self) { risk in
                Label(Self.riskTitle(risk.kind), systemImage: risk.severity == .warning ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(risk.severity == .warning ? Color.red : Color.orange)
            }
        }
        Button {
            model.copy(code)
        } label: {
            Label(model.copied ? L10n.shareCopied : L10n.commonCopy, systemImage: model.copied ? "checkmark" : "doc.on.doc")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.055, green: 0.486, blue: 0.4))
        Label(L10n.shareOpenNote, systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
        Label(L10n.shareHistoryNote, systemImage: "clock")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    static func kindTitle(_ kind: PayloadKind) -> String {
        switch kind {
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

    static func riskTitle(_ kind: URLRisk.Kind) -> String {
        switch kind {
        case .lookalikeCharacters: L10n.urlRiskLookalikeTitle
        case .disguisedHost: L10n.urlRiskDisguisedTitle
        case .shortener: L10n.urlRiskShortenerTitle
        case .insecure: L10n.urlRiskInsecureTitle
        case .ipAddress: L10n.urlRiskIpTitle
        case .unusualPort(let port): L10n.urlRiskPortTitle(String(port))
        }
    }
}
