import AppIntents
import UIKit

// Shortcuts actions (docs/DESIGN_1.2.md §6, N). They run in the app on the device, without opening it,
// and never save to the history (so an automation that runs often does not fill it).

/// "QRコードを作成": text in, a PNG of the QR code out.
struct CreateQRCodeIntent: AppIntent {
    static let title: LocalizedStringResource = "QRコードを作成"
    static let description = IntentDescription("テキストや URL から QR コードの画像（PNG）を作ります。作ったものは履歴に保存しません。")

    @Parameter(title: "テキスト", inputOptions: String.IntentInputOptions(multiline: true))
    var text: String

    init() {}

    init(text: String) {
        self.text = text
    }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$text) から QR コードを作成")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        .result(value: IntentFile(data: try Self.png(for: text), filename: "QRコード.png", type: .png))
    }

    @MainActor
    static func png(for text: String) throws -> Data {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw QRIntentError.emptyText }
        guard let image = QRCodeRenderer.image(for: text), let data = image.pngData() else { throw QRIntentError.tooLong }
        return data
    }
}

/// "画像のQRコードを読む": an image in, the content of every code in it out.
struct ReadCodesInImageIntent: AppIntent {
    static let title: LocalizedStringResource = "画像のQRコードを読む"
    static let description = IntentDescription("画像に写った QR コードやバーコードの中身を取り出します。複数あれば全部を返します。読み取りは iPhone の中だけで行い、履歴には保存しません。")

    @Parameter(title: "画像")
    var image: IntentFile

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$image) のコードを読む")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        guard let picture = UIImage(data: image.data) else { throw QRIntentError.unreadableImage }
        let codes = try await ImageCodeReader.detect(in: picture)
        guard !codes.isEmpty else { throw QRIntentError.noCode }
        return .result(value: codes.map(\.content))
    }
}

enum QRIntentError: Error, CustomLocalizedStringResourceConvertible {
    case emptyText
    case tooLong
    case unreadableImage
    case noCode

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyText: "QR コードにするテキストが空です。"
        case .tooLong: "テキストが長すぎて、QR コードにできません。"
        case .unreadableImage: "画像を読み込めませんでした。"
        case .noCode: "画像からコードが見つかりませんでした。"
        }
    }
}
